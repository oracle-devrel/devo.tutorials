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
slug: nodejs-sendmail-oci
---
*Oracle Cloud Infrastructure (OCI) [Email Delivery]* is an email notification service that provides a fast and reliable managed solution for sending high-volume emails that need to reach your recipients’ inbox. Email Delivery provides the tools necessary to send application-generated email for mission-critical communications such as receipts, fraud detection alerts, multi-factor identity verification, and password resets.  

In this tutorial, we'll cover all the basics to get you up and running with the Email Delivery service!  

## Set up Email Delivery

1. Go to **IAM/user** and select **Generate SMTP Credentials** as shown below:  

   {% imgx assets/ociemailimage-6.jpg  %}

1. Keep the credentials created in a safe place:  

   {% imgx assets/ociemailimage-7.jpg %}

1. Create an **Approved Sender** (a real, existing email account to put in the **from** field):  

   {% imgx assets/ociemailimage-8.jpg %}

1. Grab the connection details:  

   {% imgx assets/ociemailimage-9.jpg %}

1. Now, test the code:  

      ```console
      npm install [nodemailer](https://nodemailer.com/about/)
      ```

1. Create a `sendmail.js` file:  

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

## Test the configuration

Now that you have Email Delivery set up, let's verify that everything is working properly.  In a console window, run:  

```console
node sendmail.js
```

{% imgx assets/ociemailimage-10.jpg %}
{% imgx assets/ociemailimage-11.jpg %}

And that's it! If your local output is similar to what's shown above, you're all set and ready to receive notification emails!  

## What's next

If you’re curious about the goings-on of Oracle Developers in their natural habitat, come join us on our [public Slack channel]!

And don't forget our [free tier], where you can try out what we just discussed.

To explore more information about development with Oracle products:

* [Oracle Developers Portal]
* [Oracle Cloud Infrastructure]

<!--- links -->
[Email Delivery]: https://docs.oracle.com/en-us/iaas/Content/Email/Concepts/overview.htm

[public Slack channel]: https://oracledevrel.slack.com/join/shared_invite/zt-uffjmwh3-ksmv2ii9YxSkc6IpbokL1g#/shared-invite/email
[free tier]: https://signup.cloud.oracle.com/

[Oracle Developers Portal]: https://developer.oracle.com/
[Oracle Cloud Infrastructure]: https://www.oracle.com/cloud/
