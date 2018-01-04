+++
title = "OWASP Kyiv Meetup, Winter 2017"
slug = "owasp-kyiv-2017-winter"
date = 2018-01-04T18:14:50Z
desc = "Things that I've learned at the recent meetup of the Kyiv OWASP chapter."
tags = ["security", "meetup"]
+++

Last year I got interested in the security field. Partially, because of accidentally falling into it, but also all the news around botnets, ransomware, and breaches just would not leave my awareness bubble.

Coincidentally, thanks to awesome organisers, this year Kyiv got its very own [<abbr title="The Open Web Application Security Project">OWASP</abbr> chapter][OWASP Kyiv]! So far they've had three meetups. Unfortunately, I missed the first one but attended the second, and they were kind enough to allow me to give a talk at the third.

This post contains some highlights and notes on the talks I attended from the last, Winter 2017 meetup. Any mistakes below most certainly are my own and not the speakers.<br/>
*Note that while presentations were not in English, most slides are.*

## Don’t Waste Time on Learning Cryptography: Better Use It Properly, Anastasiia Vixentael

In her talk, Anastasiia argues that using cryptography for the basic case of data encryption and decryption is needlessly complicated. There are usual suspects involved: cyphers, modes, hashes, key lengths, <abbr title="Initialization Vector">IV</abbr>s. Then, add to those all the required infrastructure for secrets management, backups, etc. It's just too many choices with lots of hidden traps. Using a nice visual metaphor from the talk, it all builds into a [“Wall of Insanity.”][vixentael's wall]

Proposed solution: boring crypto. As I understood it, this is an idea of a library with usable by regular developer interface, while most of the complex decisions made by the knowledgeable author in the form of reasonable defaults. Plug’n’Play comes to crypto! Examples include [BoringSSL], [noise], [libsodium], [themis] and [keyczar].

Another interesting point from the talk: you should prefer a higher level of abstraction when choosing how to implement cryptography in your project. Prefer crypto-systems (e.g. WhisperSystems' [signal protocol], [ZeroKit], [<abbr title="Transport Layer Security">TLS</abbr>][TLS]) to crypto-libraries, and boxed solutions ([Vault], [Acra]) to crypto-systems.

I was slightly confused during the part about <abbr title="Hardware Security Module">HSM</abbr>s, <abbr title="Trusted Platform Module">TPM</abbr> and software cryptography. It seemed disconnected from the general story before and after it.

Overall, it's an excellent introduction, with a few links and things to google when embarking on enhancing project's security by adding crypto.

Links: [video][vixentael_on_crypto video], [slides][vixentael_on_crypto slides].<br/>
Follow [@vixentael][vixentael].

## SAMM: Understanding Agile in Security, Pavel Radchuk

This was a nice and short talk on the strategy and complementing tools for bringing security to the agile development called [OWASP SAMM]. The problem it solves is the same as in the previous talk (and always?)&#8239;---&thinsp;developers have lots of other tasks, no time for security.

With SAMM there's no need to go all-in, it follows native for Agile’s iterative approach:

1. perform an assessment&#8239;---&thinsp;what do we have now?
2. define goals&#8239;---&thinsp;what do we want to do better?
3. think of the ways to come a bit closer to your goals
4. do a small step towards improvement
5. go to 1

So far as intro goes, it all sounded very reasonable and, importantly, doable.

Would love to hear more about real life experience implementing SAMM, e.g. what went not so good, reasons choose something else, tools you wish existed, trade-off decisions, etc. Does anyone want to do a follow-up? 🙂

Links: [video][radchuk_on_secure_agile video], [slides][radchuk_on_secure_agile slides].

## Security Economics, Vlad Styran

I don't know how recent this is, but security people seem to have a general interest in the economics. It makes sense, of course, since both fields also study the people motivations, but economists worked on that relatively longer, and so have more to share. This talk was loosely(?) based on the recent [“Cyber Security Economics”][sec-econ course] course.

Interesting points:

* Only making more money is an incentive for vendors, not building secure things; on the other hand, consumers are motivated to spend less. In this setup both vendors and consumers would like to ignore “invisible features” like security and “promise” to add them at some point later
* All risks are on security consumers because there's always a way to blame them: wrong configuration, “human error,” etc.
* Security results are tricky to measure since “losses that didn't happen” just *aren't* there
* Compliance *is* security, but it protects from different actors, namely government and industry regulators, than firewalls or <abbr title="Intrusion Detection System">IDS</abbr>es

There was a bit that confused me: first, we imagined rational actors to build our models, studied them, and then we discover that people are (surprise!) not rational. So, shouldn’t the models be updated? How wrong are insights drawn from those models?

Links: [video][styran_on_econ_of_security video], [slides][styran_on_econ_of_security slides].<br/>
Follow [@c2FwcmFu][styran].

## Modern SSL Pinning, Dima Kovalenko

This was an especially fun talk on the <abbr title="Secure Sockets Layer">SSL</abbr>/<abbr>TLS</abbr> pinning techniques as Dima presented it from the perspective of the security researcher or attacker. I’d keep reminding myself that occasional _“Everything got worse”_ for a defence side means diametrically opposite: _“Everything got better!”_

A brief history of the cat-and-mouse game of app developers and people reversing their <abbr>API</abbr>s (examples for iOS, but it's similar with Android):

* at first, switch from <abbr>HTTP</abbr> to <abbr>HTTPS</abbr> was meant to prevent <abbr title="Man-in-the-middle">MITM</abbr> attacks
* it's trivial to circumvent by adding your cert to the system's cert storage
* probably annoyed by all the bots, developers added certificate pinning to make it harder to reverse their <abbr>API</abbr> and started bundling, or just downloading on the first start their certs, so that modifying global system storage became useless
* [SSLKillSwitch] appears that hooks into the system's <abbr>SSL</abbr> stack, basically replacing function `verifyCert()` with something that always returns `true`
* developers now began using custom <abbr>SSL</abbr> implementations (mostly just [OpenSSL]), so that SSLKillSwitch no longer works with a lot of popular apps, but still works with ones that have less engineering power behind them
* with rooted device it’s still just a matter of time, and enough motivation to find the function to hook into, again making the <abbr>SSL</abbr> check always succeed

Things are “easier” on the Android since it’s more open, i.e. it’s harder for developers to secure.

When asked what he thinks about the idea of boring crypto, Dima said that it sounds great for reversers because it means one will be able to use the same method working with more than one app, similarly to how it was at the time of SSLKillSwitch.

Links: [video][kovalenko_on_ssl_pinning video], [slides][kovalenko_on_ssl_pinning slides].<br/>
Follow [@kov4l3nko][kovalenko].

## My talk

I also gave a talk, but it will be in a separate post. Stay tuned! 😉

## Summary

It was an excellent meetup, and I'm looking forward going again. Huge thanks to OWASP for sponsoring, chapter leaders for starting and continuing work on this whole thing, and speakers for sharing your knowledge and experience!

By the way, they've just [announced the next meetup][announcement] on March 3rd and you should [submit a CFP!][CFP] Registration will open a bit later, on the 1st of February. You should follow [OWASP Kyiv twitter] for future announcements.

[OWASP Kyiv]: https://www.owasp.org/index.php/Kyiv
<!-- speaker links -->
[vixentael]: https://twitter.com/vixentael
[vixentael's wall]: https://speakerdeck.com/vixentael/dont-waste-time-on-learning-cryptography-better-use-it-properly?slide=21
[vixentael_on_crypto video]: https://youtu.be/SfuN-r3FpdY
[vixentael_on_crypto slides]: https://speakerdeck.com/vixentael/dont-waste-time-on-learning-cryptography-better-use-it-properly
[radchuk]: ???
[radchuk_on_secure_agile video]: https://youtu.be/nOrlK4p7QA8
[radchuk_on_secure_agile slides]: https://speakerdeck.com/owaspkyiv/pavel-radchuk-samm-understanding-agile-in-security
[styran]: https://twitter.com/c2FwcmFu
[styran_on_econ_of_security video]: https://youtu.be/vZAldeJ-_rw
[styran_on_econ_of_security slides]: https://speakerdeck.com/sapran/vlad-styran-security-economics
[kovalenko]: https://twitter.com/kov4l3nko
[kovalenko_on_ssl_pinning video]: https://youtu.be/MeZINw4GnGM
[kovalenko_on_ssl_pinning slides]: https://kov4l3nko.github.io/blog/2017-12-02-owasp-kyiv-winter-2017/
<!-- talk links -->
[BoringSSL]: https://boringssl.googlesource.com/boringssl/
[noise]: http://noiseprotocol.org/
[libsodium]: https://libsodium.org/
[themis]: https://github.com/cossacklabs/themis
[keyczar]: https://github.com/google/keyczar
[signal protocol]: https://github.com/whispersystems/libsignal-protocol-java
[ZeroKit]: https://tresorit.com/zerokit/
[TLS]: https://en.wikipedia.org/wiki/Transport_Layer_Security
[Vault]: https://www.vaultproject.io/
[Acra]: https://www.cossacklabs.com/acra/
[OWASP SAMM]: https://www.owasp.org/index.php/OWASP_SAMM_Project
[SSLKillSwitch]: https://nabla-c0d3.github.io/blog/2013/08/20/ios-ssl-kill-switch-v0-dot-5-released/
[OpenSSL]: https://www.openssl.org/
[sec-econ course]: https://www.edx.org/course/cyber-security-economics-delftx-secon101x-0
<!-- summary links -->
[announcement]: https://twitter.com/owaspKyiv/status/947803273951670272
[CFP]: https://easychair.org/cfp/OK-Q1-2018
[OWASP Kyiv twitter]: https://twitter.com/owaspKyiv
