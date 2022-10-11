---
title: Creating a Simple Chatbot using NodeJS on OCI
parent:
- tutorials
toc: false
tags:
- open-source
- oci
- nodejs
languages:
- nodejs
categories:
- frameworks
- cloudapps
thumbnail: assets/racterexaemplasdfsdfsdf.jpg
description: A very basic chatbot using nodejs on an oracle cloud compute instance.
date: 2022-05-26 19:42
mrm: WWMK220210P00063
author:
  name: Victor Agreda
slug: create-simple-chatbot-nodejs-oci
---
## Introduction: Why this?

{% imgx assets/racterexaemplasdfsdfsdf.jpg %}

When I started this project I wanted to make a Racter-like chatbot. For those who don't remember, Racter was a weird little text "conversation simulator" released in the 1980s by publisher Mindscape, known for educational software. I wound up playing quite a bit on my dad's Apple //c instead of my computer because his had a printer, and you could print out conversations -- presumably to share them with friends. A literal "share sheet," if you will.

{% imgx assets/apple2cvhanodejsasdfsd.jpg %}

However, what I wound up doing is establishing the beginnings of a home assistant. Racter is pretty outdated tech, as it just takes nouns you say and adds them into sentences. Very much like Mad Libs, but weirder. You can actually [try out Racter on the Abandonware site](https://www.myabandonware.com/game/racter-4m/play-4m). Let's face it, home assistants are much more conversational and practical these days.

I have a mix of IOT devices in my home, but have lately become a fan of open source projects that integrate the disparate platforms (Amazon, Apple, and Google, primarily) and increase privacy. To start, I looked around for some existing "chatbots" and found [this clever implementation](https://github.com/Programmer101N/chatbot_nodejs) by [Naman Baranwall](https://github.com/Programmer101N), which uses a little bit of training to choose the best response. Obviously we'll be adding to this later, but for now, I wanted to show how to get this up and running on Oracle Cloud Infrastructure (OCI). It was honestly a lot easier than I thought it would be! But note that we're going for the shortest distance between two points, and that's getting the application running using NodeJS. If this were a production environment, we'd likely use bastions and some stricter access controls. All in good time!

## Pre-Requisites

* OCI Free Tier account
* Wait, that's it???

You may want a GitHub account if you want to branch the project as I did for extension later, but honestly this is all so simple you'll be amazed.

## Steps

1.  Create a compartment

	Menu: Identity and Security > Instances

	{% imgx assets/2instancesinmycompartment.png %}

	The point is that we're not messing about in our root compartment, just as we like to avoid mucking about in root on our personal machine, right? I created a very simple compartment and just made the parent my root, but I also used this for my Virtual Cloud Network (VCN) so I can connect later. Identity and Security is also where you would create users, groups, and all manner of access controls. But, it's just little ol' us, so we'll just go in as admins.

	{% imgx assets/2createinstanceinmycompartment.png %}

	{% imgx assets/2createcompartmentchatbotnodejs.png %}

2.  Create a VCN if you don't have one

	Menu: Networking > Virtual Cloud Networks

	This is where my advance prep of a compartment came in handy, as I'd already set up a VCN using default route tables and it has a public IP so I can `ssh` in later. VCN's are really powerful, but for our purposes all we need is a subnet and a public IP to steer to, all of which is easy to set up using the tool provided. Of course, almost all of these things can be automated using something like Terraform, but we're just testing a chatbot for ourselves today.

	{% imgx assets/vcnsinmycompartmentnodejsproj.png %}

3.  Create a compute instance

	Menu: Compute > Instances

	Here's where things get streamlined. Oracle does a good job of choosing a general purpose shape, but we're going to adjust it so it's free-tier and connecting to the Internet.

	{% imgx assets/2createcomputeinstancechatbotproj.png %}

	Instead of AMD, we'll go with Ampere, an exceptionally good value (free-tier, remember?) just click on change shape...

	{% imgx assets/2amdchangeshapeinocicompute.png %}

	Also, don't forget to change the memory to 8GB

	{% imgx assets/2amperealwaysfreecomputeshapetouse.png %}

	As you scroll down, you'll see that our previous VCN is available, how handy! That means we can assign a public IP to this fellow and `ssh` in shortly.

	{% imgx assets/2computewizardnetworkingpart.png %}

	And to `ssh` in, we'll need the private key, which I just generate right here while I'm spinning up my compute, and of course save it and the public key somewhere safe (more on this in a bit).

	I personally provision 50GB of storage, but you don't have to as OCI will provision some block memory to start with.

	{% imgx assets/2privpubkeysandstorage.png %}

	*NOTE: You can save these as a stack for later use as well, which is also handy.*

	To review, we've just taken 3 steps to spin up a publicly-available free-tier compute instance so we can start creating our dev environment and chances are you haven't even finished that beverage sitting too close to your keyboard!

4.  Connecting to our compute instance

	It'll take a minute for the compute instance to spin up, but when it does, the panel will show you the public IP, which you'll need to `ssh` in. 

	Menu: Compute > Instances > Instance Details

	There's even a handy copy link!

	{% imgx assets/2computepubipexampleco.png %}

	I'm using Terminal on my Mac, so I `cd` over to where I'm storing my private key, `chmod 400` it, then:

	```console
	ssh -i <path to private key> opc@<public IP address>
	```

	And of course, when prompted by security, you want to continue connecting, which will add you to the list of known hosts and you're off to the races!

5.  Installing what we need

	As we're using nodejs, we'll want to install it and then create a folder for our project, then initialize a repo in that folder to install our modules. We'll also set up some text files with code and parameters.

	Oracle has a nifty `yum` repo for NodeJS and all we need to do is install the latest NodeJS using this command: 

	```console
	sudo yum install nodejs
	```

	Navigate to your home folder, and then `opc` (the admin user for this VM), and create a folder for your project. Like the tutorial, I named mine `chatbot_nodejs`.

	I branched the repo beforehand so I could extend it a bit later, but either way we initialize it in that folder with `npm init` and use `npm i node-nlp` to install the appropriate modules.

	Note that the `package.json` file will look for an `index.js` file, and we add two scripts: `train.js` and `index.js`, plus the repo for our dependencies.

	{% imgx assets/packagejsonfileshownchatbot.png %}

6.  Writing and testing

	The way all of this works is by storing a set of "intents" as questions and responses, then using the `node-nlp` module to weigh responses over time.

	The `train.js` file is where we have the code to actually teach our model. We also create an `index.js` file, which will get everything loaded and set up -- it's pretty simple right now, but has the capacity to extend itself to a more conversant home assistant in the future.

	As you can see in [the article](https://medium.com/geekculture/create-chatbot-with-nodejs-cf3d8bc3f302), we import the `NlpManager` from `node-nlp` so we can save and process what goes on, then create a new instance of the `NlpManager` class, read input from the terminal, send it to the manager for a response, and then display that response.

	Nothing too fancy just yet, but we're laying some important groundwork. The term "intent" here is very specific, referring to the natural language processing (NLP) we're using to train our system. This can be used in many ways, from knowing preferences to avoiding specific words to understanding what a person is saying better over time. Just like it reads, "intent" is what the person is trying to say. You can [read more about intent recognition in this excellent piece by Christopher Marshall](https://medium.com/mysuperai/what-is-intent-recognition-and-how-can-i-use-it-9ceb35055c4f).

	The model needs something to start with, so we create a couple of documents in our intents folder (inside our project folder): one for "hello" and one for "goodbye." The author creates a set of questions and answers, which can, of course, be as long as you like. I took the liberty of changing a few, including one that calls me "FNAME" as an homage to the days when I would get press releases gone horribly awry on the database side. If you know, you know.

	You could create many of these to accomodate frequent queries like weather, sports, news, etc., and then create data agents who fetch what you need and return it using phrases that (over time) will be weighed for preference and ultimately "converse" in a more natural way. Integrating live data is something we'd love to do here, but we'll wait to do this another day.

	Once I fixed my own minor syntax errors (check those commas, people!), the whole thing worked just as expected. First you run `train` to get the module initialized and ready (you'll see a bunch of timing to let you know it's doing the work), then run `start` to get the chatbot chatting.

	{% imgx assets/chatbotactuallyworkingnodejs34.png %}

## Next Steps: IOT

OK, maybe not the very next step, but eventually this could become my own little Siri or Alexa, running in OCI, tied to systems in my house, capable of giving me whatever information I need on request. Sort of like a certain comic book character who came to life on screen not too long ago...

You can try all this for yourself by setting up a free tier account, and reviewing [the article](https://medium.com/geekculture/create-chatbot-with-nodejs-cf3d8bc3f302) for the chatbot code. 
Join us on our [public Slack](https://bit.ly/devrel_slack) if you do some cool stuff with it!



