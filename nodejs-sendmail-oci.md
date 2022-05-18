---
title: Sending Emails from OCI with Email Delivery Service in Node.js
parent:
- tutorials
toc: false
tags:
- open-source
- oci
- always-free
- nodejs
- javascript
languages:
- nodejs
categories:
- frameworks
- cloudapps
thumbnail: assets/ociemailimage-10.jpg
description: Use Oracle Cloud Infrastructure to manage a high-volume email solution
  for sending out emails to many recipients for critical communications.
date: 2022-02-14 19:42
mrm: WWMK220204P00005
author:
  name: Javier Mugueta
  home: https://javiermugueta.blog/author/javiermugueta/
xredirect: https://developer.oracle.com/tutorials/nodejs-sendmail-ocii/
---
Oracle Cloud Infrastructure [Email Delivery](https://docs.oracle.com/en-us/iaas/Content/Email/Concepts/overview.htm) is an email sending service that provides a fast and reliable managed solution for sending high-volume emails that need to reach your recipients’ inbox. Email Delivery provides the tools necessary to send application-generated email for mission-critical communications such as receipts, fraud detection alerts, multi-factor identity verification, and password resets.

Go to a IAM/user and click on [Generate SMTP Credentials] as shown below:

{% imgx assets/ociemailimage-6.jpg  %}

Keep the credentials created in a safe place:

{% imgx assets/ociemailimage-7.jpg %}

Create an Approved Sender (a real existing email account to put in the from field):

{% imgx assets/ociemailimage-8.jpg %}

Grab the connection details:

{% imgx assets/ociemailimage-9.jpg %}

Now test the code:

```console 
npm install [nodemailer](https://nodemailer.com/about/)
```

Create a sendmail.js file:

```console
var nodemailer = require('nodemailer');
async function main() {
let testAccount = await nodemailer.createTestAccount();
let transporter = nodemailer.createTransport({
  host: "smtp.email.eu-frankfurt-1.oci.oraclecloud.com",
  port: 25,
  secure: false,
  auth: {
    user: 'ocid1.user.oc1..aaaaaa...om', 
    pass: 'BD..._', 
  },
});
let info = await transporter.sendMail({
  from: '"javier...om', 
  to: "javi...om", 
  subject: "ssh access to 10.0.2.94",
  html: "<b>ssh -i deltakey -o ProxyCommand=\"ssh -i deltakey -W %h:%p -p 22 ocid1.bast...oud.com\" -p 22 opc@10.0.2.94</b>", 
});
console.log("Message sent: %s", info.messageId);
console.log("Preview URL: %s", nodemailer.getTestMessageUrl(info));
}
main().catch(console.error);
```

Test it:

```console    
node sendmail.js
```

{% imgx assets/ociemailimage-10.jpg %}
{% imgx assets/ociemailimage-11.jpg %}


That’s all, hope it helps! 🙂

If you’re curious about the goings-on of Oracle Developers in their natural habitat, come join us on our [public Slack channel](https://oracledevrel.slack.com/join/shared_invite/zt-uffjmwh3-ksmv2ii9YxSkc6IpbokL1g#/shared-invite/email)!

And don't forget our [free tier](https://signup.cloud.oracle.com/?language=en), where you can try out what we just discussed.
