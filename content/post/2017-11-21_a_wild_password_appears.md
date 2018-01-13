+++
title = "A Wild Password Appears"
date = 2017-11-21T15:30:56Z
desc = "A short overview of the recent paper on users’ password habits."
tags = ["security", "paper"]
+++

Here is my overview of the paper [Let’s Go in for a Closer Look: Observing Passwords in Their Natural Habitat][Paper PDF] by Pearman et al. recently presented at [<abbr title="ACM Conference on Computer and Communications Security">ACM CCS</abbr>’17.][CCS'17]

## Paper

This is a report on a study of 154&#8239;participants’ password usage behaviours over a significant period&#8239;---&thinsp;minimum 30, average 147&#8239;days each. The most interesting things researchers looked into were a problem of password reuse, what attributes (e.g. length, composition, strength) correlate with it, and also whether the use of password managers or autofill in the browser affects reuse and password’s strength.

Piggybacking another ongoing longitudinal study called [Security Behavior Observatory][SBO], authors installed browser extensions on personal computers of participants that collected for every used password its salted hash, composition, strength as well as hashes of all of its substrings. They also checked downloads against Google Safe Browsing <abbr title="Application programming interface">API</abbr> and _“file hashes from users’ filesystems to results in VirusTotal’ database,”_ but don’t provide any more details on the latter part.

Results are rather upsetting:

- only 10&#8239;participants (6.5% of total) created unique sequences for at least 50% of their passwords, but they had online activity for just 17% of days they were in the study and have entered their passwords on eight or fewer domains
- the average participant reused (partially or fully) 79% of their passwords
- contrary to an intuitive assumption, site’s type (e.g. work, shopping, social media) doesn’t seem to correlate with the level of reuse; strangely, job-related and financial sites were shown to correlate with 3× increase in odds of reuse
- presence of a single digit in the password predicts 12× raise of reuse odds; yeah, sequences like `P@ssw0rd!1`, `P@ssw0rd!2`, `P@ssw0rd!3` and so on are a _very_ real thing
- no statistically significant effect on reuse or strength from password managers or autofill usage; authors propose a possible explanation: participants create passwords on their own and use managers only to store them

## Notes

I don’t have strong arguments for this, but I feel like the way authors aggregate data for analysis,&#8239;---&thinsp;computing mean for each participant separately and then mean, median and standard deviation of these means,&#8239;---&thinsp;could introduce artefacts, but they don’t address this. I’ll try to investigate this later.

Also, I don’t think we can make any conclusions about password managers and autofill. In the _Methodology_ section, authors say that keystroke data collection, a dataset that later allowed distinguishing a copy-paste or autofill from the regular password input, was done during just the last seven weeks of the study. It’s not clear how they were detecting a presence of password manager (using keystroke data or not?), but only 19&#8239;participants had them. I’d say there’s still not enough data on this.

[Paper PDF]: https://acmccs.github.io/papers/p295-pearmanA.pdf
[CCS'17]: https://acmccs.github.io/papers/
[SBO]: http://sbo.cs.cmu.edu/
