+++
title = "Cloudflare Demo Token Leak"
date = 2024-01-02T23:56:47+02:00
slug = "cloudflare-demo-token-leak"
desc = "This is a story about how I noticed an active API token for Cloudflare’s internal domain leaked by their own docs"
type = "post"
tags = ["security"]
+++

In early March 2022, I was looking for something to do.
_Anything_ really to distract me from the stream of horrible news after [russia invaded][invasion] my country. One of the “projects” I picked up, was an attempt to learn Terraform by writing down configuration for a couple of my static sites.

That’s what brought me to Cloudflare’s [Create an <abbr>API</abbr> token][cf-create-token-page] documentation page.
There, the following screenshot caught my attention — see if you notice anything odd about it before you continue reading:

{{< fig
	class="white"
	src="media/original_token-complete.png"
	caption="*(Click on the image to open the full-size version)*"
	alt="A screenshot of the “API Tokens” page with two sections: on the top “Edit zone DNS API token was successfully created” which has a field whose value is hidden behind a white box with the text “Your API Token Secret Here!”, and below it a “Test this token” with a cURL command demonstrating a GET request to “/users/tokens/verify” endpoint with “Authorization” header" >}}

Interestingly, as you can see, after you create an <abbr>API</abbr> token, Cloudflare’s UI shows it twice on the same screen: once in a text field for easy copying and also below that, embedded in a `curl` command showing how to test it.

What’s weird is that the author of a screenshot obscured only the first text field with the opaque “Your <abbr>API</abbr> Token Secret Here!” box.
Could they leave this demo token unrevoked because they assumed they hid it properly? 🤔

Yes! Yes, they did! The `curl` command worked[^1]:

```
$ curl -sSL "https://api.cloudflare.com/client/v4/user/tokens/verify" \
       -H "Authorization: Bearer tvjU0CzJMzE5Y-KMjlMHweRCDTfw1LgCiASmkUan" \
       -H "Content-Type:application/json" | jq '.'

{
  "result": {
    "id": "<edited out ID>",
    "status": "active"
  },
  "success": true,
  "errors": [],
  "messages": [
    {
      "code": 10000,
      "message": "This API Token is valid and active",
      "type": null
    }
  ]
}
```

After some probing, I found that the token had access to a [zone][dns-zone] for `theburritobot.com` — an&nbsp;example domain, Cloudflare uses in its blog ([1][cf-demo-domain-ex1], [2][cf-demo-domain-ex2]) and docs ([3][cf-demo-domain-ex3], [4][cf-demo-domain-ex4]) for showing various features.

Ok, the token _is_ active, but I assumed it has only read permissions.
The “Edit zone DNS” is just a default token name.

Nope!
Checking for write access, I tried adding a <abbr>TXT</abbr> record (`iv` here is my initials):

```
$ cat <<EOF >request.json
{
  "type": "TXT",
  "name": "_iv-token-test.theburritobot.com",
  "content": "20220310",
  "ttl":3600,
  "proxied":false
}
EOF

$ curl "https://api.cloudflare.com/client/v4/zones/<zone ID>/dns_records" \
       -H "Authorization: Bearer tvjU0CzJMzE5Y-KMjlMHweRCDTfw1LgCiASmkUan" \
       -H "Content-Type:application/json" \
       --data '@request.json'
```

The record appeared for everyone to see:

```
$ dig _iv-token-test.theburritobot.com TXT +noall +answer @1.1.1.1

_iv-token-test.theburritobot.com. 3600 IN TXT   "20220310"
```

Now, it was time to report this to someone.

## Reporting

I tried checking for `security.txt`[^2] and was happy to find that Cloudflare [supports it][cf-security.txt].
It was extra exciting because I was using something I heard about from professional _“security people”_ online, and it worked the first time!

The policy file points to [HackerOne][h1-cf] as a way to contact their security team.
So, I filled a bug: [[1507412] <abbr>API</abbr> docs expose an active token for the sample domain theburritobot.com][h1-report].

At the time, I didn’t expect anything more than a “thank you” and permission to share this as a funny story.
But David from Cloudflare, who triaged my report, was kind enough to consider `DNS:edit` permission on an internal zone to be worth High severity and a $500 bounty.

The token was revoked almost immediately.
At some point later in 2022 doc writers replaced the screenshot with its current version:

{{< fig
	class="white"
	src="media/current_token-complete.png"
	alt="Similar “API Tokens” screenshot as before, but with site navigation panes cropped out, with two sections: on the top “Edit zone DNS API token was successfully created” which has a field whose value is only partially hidden behind an opaque grey box, and a “Test this token” showing the same sample cURL command that has “Authorization” header’s value also partially obscured by a grey box" >}}

Someone learns from their mistakes!

## Money

Unfortunately, HackerOne ignored my support requests asking to donate the money for about six months.
I vaguely remember someone from the company somehow blamed it on the war, but it was on Twitter and I don’t have a link.

Then, I started a new job and just didn’t have the energy to chase them.

Finally, it took some time to find a charity supporting Ukraine that HackerOne is “able” to donate to[^3].
On December 18th 2023 I was told they successfully donated the bounty money to [Razom][razom].

## Conclusion

I don’t have any smart advice to conclude this story with.

It can be fun (and sometimes even profitable) to notice weird little things, be curious and spend a minute investigating them, I guess?

The end.


[^1]: The output is recreated while I’m writing this post because I didn’t save it at the time
[^2]: This file is the proposed standard place for the security contacts and more; see [securitytxt.org][about-security.txt]
[^3]: I got a very polite email from (I assume based on the “from” address) a HackerOne employee stating that they were “unable to make the donation” to [Hospitallers][hospitallers], without any clarification as to why, even though their support confirmed earlier that it should work

[invasion]: https://en.wikipedia.org/wiki/Russian_invasion_of_Ukraine
[cf-create-token-page]: https://developers.cloudflare.com/fundamentals/api/get-started/create-token/
[dns-zone]: https://en.wikipedia.org/wiki/DNS_zone
[cf-demo-domain-ex1]: https://blog.cloudflare.com/how-and-why-the-leap-second-affected-cloudflare-dns
[cf-demo-domain-ex2]: https://blog.cloudflare.com/introducing-custom-hostname-analytics
[cf-demo-domain-ex3]: https://developers.cloudflare.com/logs/get-started/enable-destinations/http/#example-curl-request
[cf-demo-domain-ex4]: https://developers.cloudflare.com/security-center/intel-apis/#miscategorization-intelligence
[about-security.txt]: https://securitytxt.org/
[cf-security.txt]: https://www.cloudflare.com/.well-known/security.txt
[h1-cf]: https://hackerone.com/cloudflare
[h1-report]: https://hackerone.com/reports/1507412
[hospitallers]: https://www.hospitallers.life/needs-hospitallers
[razom]: https://www.razomforukraine.org/
