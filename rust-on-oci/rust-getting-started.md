---
title: Getting started with Rust
parent:
- tutorials
- rust-on-oci
tags:
- open-source
- devops
- get-started
- back-end
- rust
categories:
- clouddev
- cloudapps
date: 2022-12-12 08:00
description: The beginning of a series on building applications using the Rust programming language.
toc: true
author: oracle-developers
slug: rust-getting-started
---
{% imgx alignleft 250 250 media/image2.png "Rust Logo" "Rust Logo" %}
{% imgx alignleft 250 250 media/image1.png "Rust Cargo Logo" "Rust Cargo Logo" %}
{% imgx alignleft 250 250 media/image4.png "Ferris the crab, unofficial mascot" "Ferris the crab, unofficial mascot" %}

Welcome to a series of posts on "Everything you need to know about Rust." We'll cover a lot over the course of the next few articles. By the end, you should be comfortable with writing and deploying your own Rust project and be ready to jump into advanced topics.

This first article will introduce you to the motivations behind Rust, why you might use Rust, and a walkthrough of a simple Rust application deployed to Oracle Cloud Infrastructure. Later articles will cover the ecosystem and full suite of Rust tools, publishing Rust libraries (known as "crates"), and best practices and resources for becoming a Rust expert.

Let's kick it off with a few fundamentals.

## What Is Rust?

**Rust** is a general-purpose programming language developed

specifically to run blazingly fast, enforce type safety, and provide concurrency, all in an easier-to-use language than its predecessors, such as C and C++. It's a relatively new language, with version 1.0 released in 2015.

Rust enforces memory safety through [its unique ownership system](https://doc.rust-lang.org/book/ch04-00-understanding-ownership.html), which ensures that all resources are properly initialized and cleaned up, preventing you from using a resource before it has been initialized or after it has been freed. By enforcing such strict memory guarantees, Rust programs don't need to be garbage-collected. Rust also has [strong support for multithreading](https://doc.rust-lang.org/book/ch16-00-concurrency.html). In other languages, multithreading can lead to concurrency problems such as resource deadlocks. But by using the ownership system, Rust tracks and catches potential data races at *compile time*, making it much easier to write safe, concurrent code.

Many of Rust's goals are closely aligned with [Oracle Cloud Infrastructure (OCI)](https://www.oracle.com/cloud/why-oci/), which makes the two technologies a great pair if you're looking to provide greater security, performance, *and* flexibility to your development projects.

## Why Use Rust?

While Rust is definitely a general-purpose language, there are some common use cases where it truly shines.

First are **[networking](https://www.rust-lang.org/what/networking) and [embedded](https://www.rust-lang.org/what/embedded) devices.** One of the main motivators for Rust's development was to create a language that would be suitable for use in systems programming contexts, such as operating systems, device drivers, and embedded systems. Since well-written Rust applications have a small footprint and writing safe, concurrent code is a basic part of developing in the language, Rust is perfect for low-resource deployments that are often found in both of these spaces.

Next, since Rust became prominent when Mozilla sponsored it during a high point of web development, it should be no surprise that Rust has great **web-related applications**. Whether you need to have all the benefits of the language on the front end or back end of your web stack, you can use Rust.

- For front-end functionality that needs high performance, developers often build in Rust and [compile to WebAssembly](https://www.rust-lang.org/what/wasm) to run in a browser. With client-side code that is known to be safe, you can be more certain of success for whatever high-performance tasks you need.
- For back-end applications, Rust has several web frameworks, such as [Actix Web](https://actix.rs) and [Rocket](https://rocket.rs), that can provide the tools and libraries you need to quickly spin up fast and secure web applications that take advantage of Rust.

Finally, Rust is also great for **[building command-line tools](https://www.rust-lang.org/what/cli)**. With its easy distribution model (via [crates.io](https://crates.io), its package distributor) and the ability to run on many different CPU architectures, Rust allows safety and performance without having to worry about the intricacies of its deployment environment.

## How Is Rust Different from JavaScript?

You may be wondering how Rust is different from JavaScript or other scripting languages. There are a few key differences to consider.

- First, Rust is a statically typed language, while JavaScript is dynamically typed. This means that in Rust, you have to declare the types of variables ahead of time, while in JavaScript, you don't need to do this.
- Second, Rust is compiled to native code, while JavaScript is interpreted by a virtual machine. This means that Rust programs will generally run faster than JavaScript programs, but they may take longer to compile.
- Finally, Rust has several features that make it more suitable for use in systems programming contexts than JavaScript. These include its focus on safety and security, its low-level control over memory management and data layout, and its support for efficient code.

## Let's See It in Action

Now that we have some background, let's get Rust up and running on an OCI instance and see how easy it can be to get started.

If you don't have an OCI account, the first step is to create one. For simplicity and ease of following along, we'll start with [an Always Free Instance](https://www.oracle.com/cloud/free/) and create a simple Actix web app. This app will be very similar to a demo Express.js application. It's a single-file app that responds with a greeting on a couple of GET routes and will echo the payload sent via POST on another route.

Everything we use here is free, so no worries about costs.

### In order to bake a Rust app, you must first invent a computing universe

If you really wanted to go quickly, you could start by creating a bare Linux instance on OCI, install Rust, then build your Actix app. However, if you want to be able to access your app from the internet, or do more than just write to the local drive, there's a bit more involved.

We'll walk through the relevant steps below, but if you need more detailed information, check [this more thorough
tutorial](https://docs.oracle.com/en-us/iaas/Content/GSG/Reference/overviewworkflow.htm#Tutorial__Launching_Your_First_Linux_Instance).

#### Initial setup


Our first step is to [choose a compartment](https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/choosingcompartments.htm#Choosing_a_Compartment) where we'll put this sample app. If you've never created a compartment before, you'll have a default "root" compartment for your account, but it's a better idea to create a new one. We won't be creating much for this article, but having a dedicated compartment will make cleanup easier. It's simple to create one, so we'll make a sandbox compartment from the Identity & Security menu.

{% imgx media/image8.png %}

*Choose "Compartments" from the menu for Identity & Security*

Once you get to the list of compartments, you can make a new one and fill in these details (or something like them), but keep the Parent Compartment set to your root compartment.

{% imgx media/image3.png %}

Now that you have a compartment that won't cause problems for other things in the rest of your account, let's get to work.

#### An internet accessible network

In any new OCI account, you'll start with a purely private network. This means that any resources you create will be able to talk to one another, but by default, none of them will be accessible to the rest of the internet.

Since we're building a web app, that simply won't work for our needs, so we're going to need to create [an internet-connected Virtual Cloud Network](https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/creatingnetwork.htm#Creating_a_Virtual_Cloud_Network). OCI is designed to get us up and running quickly and offers just what we need through a convenient wizard on the networking page.

If you choose our sandbox compartment from the sidebar and click the "Start VCN Wizard" button, you'll see something like this.

{% imgx media/image7.png %}

Start the wizard and pick a name for your network (e.g. RustNet or whatever you feel like). Leave the CIDR blocks and other settings alone, then click next.

{% imgx media/image5.png %}

You should see a number of gateways that will be created, as well as some security lists and route tables. Click create and watch OCI do its work.

While you're here, open the Default Security List from the Security Lists tab and add a rule to allow traffic on port 8080 to your VNC. The settings should look like this:

{% imgx media/image6.png %}

#### Building our compute instance


Now we get to [make our computer](https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/launchinginstance.htm#Launching_a_Linux_Instance) for building a Rust app. We'll use the basic defaults (they're set to use the Always Free options), and we'll download the SSH key that's generated with our instance. The defaults are good enough for our purposes, so once you've given your instance a name and have checked that your VCN is being used for this instance, just click the Create button.

Once your instance has been provisioned, grab the IP address and get ready to start working in the cloud!

### Getting up and running with Rust


By default, Rust is not installed in OCI instances. However, just as OCI is designed for ease of use and setup, Rust is constantly striving for developer efficiency, and the setup process is no exception. The rustup command is designed to make setting up Rust as painless as possible.

[Grab the installation command from the docs](https://www.rust-lang.org/tools/install), and run it on your OCI instance. When you see "Rust is installed now. Great!" you're ready to go, with a full Rust tool suite installed. These tools include rustup itself, which will allow you to maintain your Rust tools in the future, rustc, which is the Rust compiler, and cargo, which serves as Rust's package manager. Cargo has many other uses too, including making new Rust apps and libraries from scratch.


Make sure to check if there are any instructions to get your current shell configured properly. If there are, run those commands. If you like, you can verify that everything was installed correctly with:

```console
rustc --version
```

This should give you the most recent and stable version of Rust.

### Configuring our app

[Getting a new Actix app going](https://actix.rs/docs/getting-started/) is pretty straightforward. You start, as you do with many Rust projects, with:

```console
cargo new hello-rust
```

**Cargo** is Rust's dependency and app manager. It's very similar to npm
for Node, Ruby's bundler tool, or PyPI for Python. In our case, it only
creates a couple things for us. In a new directory called hello-rust,
Cargo will have created the following structure:

```
hello-rust\
├── Cargo.toml\
└── src\
└── main.rs
```

In Rust, packages are called crates. The Cargo.toml file serves as a package manifest) and the src/main.rs file is our main source file. We won't need anything other than these two files for our Actix app.

In the Cargo.toml file, add the following line to the \[dependencies\] section:

```
[dependencies]
actix-web = "4"
```

Save your Cargo file and open the src/main.rs file. Replace what's there with:

```rust
use actix_web::{get, post, web, App, HttpResponse, HttpServer, Responder};

#[get("/")]
async fn hello() -> impl Responder {
    HttpResponse::Ok().body("Hello, Rust!")
}

#[post("/echo")]
async fn echo(req_body: String) -> impl Responder {
    HttpResponse::Ok().body(req_body)\
}

async fn manual_hello() -> impl Responder {
    HttpResponse::Ok().body("Hey there!")
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        App::new()
            .service(hello)
            .service(echo)
            .route("/hey", web::get().to(manual_hello))
    })
    .bind(("0.0.0.0", 8080))?
    .run()
    .await
}
```

This might feel like a lot, but with just the actix-web dependency and these few lines of code, we now have a fully functioning Rust web app.


This code, in the main function, is building an HTTP server that attaches to port 8080 of your instance. That server has two "services"

defined as asynchronous functions which will respond with a greeting at the root route with a GET or echo back a response at the /echo route. We've also established a third route manually with the .route call for the manual_hello function. Because all of these are defined using the async keyword, the app can respond to multiple requests at once as long as there are threads available. What's nice is that we know the app is not going to have any memory safety issues because it compiles without errors.

We've already opened a rule on our network to allow traffic over port 8080, but we also need to open port 8080 in our firewall to allow traffic through, so run these two commands:

```console
$ sudo firewall-cmd --permanent --zone=public --add-port=8080/tcp
$ sudo firewall-cmd --reload
```

Return to the root of your app and run:

```console
$ cargo run
```

Once you do, your application will build and start running.

If you grab the IP address of your instance and append port 8080, you should be able to get a "Hello, Rust!" from your browser. If you'd like to be a little more adventurous, you could send a POST to the /echo endpoint and get the request body you send echoed back. We've also manually set up a special hello at the /hey route. All of this in under 30 lines of Rust!

# Conclusion


There's a lot more to learn, but hopefully you can see the power and ease of using Rust and OCI together. Future articles will dive deeper into Rust and the ecosystem. In the meantime, you might also enjoy getting a taste of what Rust can do by checking out [The Rust Programming Language](https://doc.rust-lang.org/book/title-page.html), affectionately referred to by Rust programmers as "The Book." Alternatively, you can keep poking around with some of [the amazing things you can do on OCI](https://docs.oracle.com/en-us/iaas/Content/GSG/Concepts/baremetalintro.htm) with the free trial credits you got for creating a new Oracle Cloud account.
