---
title: Building an API in Rust and hosting on Oracle Cloud Infrastructure
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
description: How to build an API using Rust and host it on Oracle Cloud Infrastructure.
toc: true
author:
  name: 
slug: rust-building-an-api
---
It's impossible to work in cloud services without hearing about Rust, the system's programming language from Mozilla. It's used all over the internet by companies like [Cloudflare][1], [Facebook][2], and [Discord][3]. It's a strongly-typed yet flexible language that emphasizes strict guidelines around memory usage, making it blazing fast and resource lean. The language also focuses on developer productivity, which is evident in their tooling and [package ecosystems].

Rust is being used in places where C worked best, due in part to its recognizable syntax. It is also replacing some higher-level languages, like Node and Ruby. In this blog post, we will build a small API microservice using Rust. APIs are generally used in situations where services---a server and a client---must communicate with each other. Our API will represent the backend for an inventory bookstore, where books can be added, fetched, and removed.

This app will be hosted on Oracle Cloud Infrastructure (OCI). OCI enables cloud-native containers to run in highly secure and performant environments that are also fully managed. This makes it a perfect match to host Rust applications, since the platform and the language are well-suited to solve similar problems.

## Prerequisites

Before getting started, you'll need to install several software packages.

First, you'll need Rust. Regardless of your operating system, [the Rustup script][4] is guaranteed to work and installs all the necessary tools you need to start building a Rust application. You'll also need to install [Docker][5] to test the app containerization locally.

In order to deploy the app online, you'll also need [a free OCI account][6].

## Getting started with the Rust code

As with many programming languages, Rust comes with its own package management system called [Crates][7]. To start building our app, we will want an HTTP web framework to do the heavy lifting for us. There are many to choose from, but we'll use [warp][8], as it's both popular and performant. Just as Node uses package.json to manage packages, Rust uses Cargo.toml.

Create a new directory within which you can start building this project, and create a file named Cargo.toml in it. Paste these lines into that file:

```
[package]
name = "server"
version = "0.1.0"
license = "MIT"
edition = "2018"

[dependencies]
tokio = { version = "1", features = ["full"] }
warp = "0.3"
serde = { version = "1", features = ["derive"]}
serde_json = "1.0"
```

Here, we're defining the general metadata of our package. We're specifying that we want to create a binary executable named server; we also have a list of dependencies that our project needs, including warp.

Next, create a directory called src, and a directory called bin within that. Then, create a file called server.rs, and paste these lines into it:

```rust
#![deny(warnings)]
use warp::Filter;

#[tokio::main]
async fn main() {
    // Match any request and return hello world!
    let routes = warp::any().map(|| "Hello, World!");

    warp::serve(routes).run(([127, 0, 0, 1], 3000)).await;
}
```

We've defined a very basic Warp server, which will run on [http://127.0.0.1:3000][9]. When a user visits that page, they'll see a greeting. Go ahead and type `cargo run` on the terminal. Cargo will download all the dependencies you defined, then it'll compile them together with the server.rs file to create an executable. (All of that in just one command!) When it's finished, you'll see the following message:

```console
$ cargo run
Finished dev [unoptimized + debuginfo] target(s) **in** 0.06s
Running `target/debug/server`
```

Navigate your browser window to [http://127.0.0.1:3000][9], which should show the greeting, thus confirming that the initial project setup has worked!

## Setting up an API

Now that we have verified that our server runs correctly, it's time to build a more proper API. We want our API to get a list of books, add a new book, and remove a book.

In a future blog, we will integrate with a backend database for storing and querying the data. To keep things simple in this tutorial, we'll just fake the data store by defining an array to store all of our books.

Let's start by defining the structure of a Book. Rust has the concept of structs, which are akin to lightweight classes. Here's an example of what our Book class would look like:

(All the code below replaces the code in the server.rs file.)

```rust
use serde::{Deserialize, Serialize};                                  
                                                                     
#[derive(Clone, Serialize, Deserialize)]                            
pub struct Book {                                                  
  title: String,                                                       
  author: String,
  year: u32,
}
```

We can then modify our main function to immediately set up a basic catalog of books that follow this structure. We will use a vector (which is like an expandable array), and store the list in memory:

```rust
use std::sync::Arc;
use tokio::sync::Mutex;

pub type Db = Arc<Mutex<Vec<Book>>>;

#[tokio::main]
async fn main() {
  let mut book_catalog: Vec<Book> = Vec::new();
  book_catalog.push(Book {
    title: "The Hitchhiker's Guide to the Galaxy".to_string(),
    author: "Douglas Adams".to_string(),
    year: 1979,
  });
  book_catalog.push(Book {
    title: "The Restaurant at the End of the Universe".to_string(),
    author: "Douglas Adams".to_string(),
    year: 1980,
  });
  book_catalog.push(Book {
    title: "Life, the Universe and Everything".to_string(),
    author: "Douglas Adams".to_string(),
    year: 1982,
  });
  book_catalog.push(Book {
    title: "So Long, and Thanks for All the Fish".to_string(),
    author: "Douglas Adams".to_string(),
    year: 1984,
  });
  book_catalog.push(Book {
    title: "Mostly Harmless".to_string(),
    author: "Douglas Adams".to_string(),
    year: 1992,
  });

  let db = Arc::new(Mutex::new(book_catalog));
```

So far, so good? Right on!

The next task is to add routes to this API. There are a number of patterns to implement this, but the one suggested by Warp takes a two-pronged approach: First, the routes are defined, and then, the implementation of those routes is defined. This way, the implementation can change, but the route information can be considered static and stable.

Let's go ahead and define these routes. We'll drop the code first, and then provide a closer examination:

```rust
mod filters {
  use super::Db;
  use super::Book;
  use super::handlers;
  use warp::Filter;
  use std::convert::Infallible;

  /// The routes, combined.
  pub fn construct_book_routes(
    db: Db,
  ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    route_get_books(db.clone())
      .or(route_post_books(db.clone()))
      .or(route_delete_book(db.clone()))
  }

  /// GET /books
  pub fn route_get_books(
    db: Db,
  ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("books")
      .and(warp::get())
      .and(with_db(db))
      .and_then(handlers::get_books)
  }

  /// POST /books with JSON body
  pub fn route_post_books(
    db: Db,
  ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("books")
      .and(warp::post())
      .and(json_body())
      .and(with_db(db))
      .and_then(handlers::create_book)
  }

  /// DELETE /books/:id
  pub fn route_delete_book(
    db: Db,
  ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("books" / u64)
      .and(warp::delete())
      .and(with_db(db))
      .and_then(handlers::delete_book)
  }

  pub fn with_db(db: Db) -> impl Filter<Extract = (Db,), Error = Infallible> + Clone {
    warp::any().map(move || db.clone())
  }

  pub fn json_body() -> impl Filter<Extract = (Book,), Error = warp::Rejection> + Clone {
    // When accepting a body, we want a JSON body
    warp::body::content_length_limit(1024 * 16).and(warp::body::json())
  }
}
```

This might look like a lot of code, but we're really just redefining similar path structures in composite functions. Let's take a look at the first function:

```rust
/// The routes, combined.
pub fn construct_book_routes(
  db: Db,
) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
  route_get_books(db.clone())
    .or(route_post_books(db.clone()))
    .or(route_delete_book(db.clone()))
}
```

The only responsibility of construct_book_routes is to assemble a list of all the known routes. To make use of this, we must go back into our main function and change the final lines to look something like this:

```rust
warp::serve(filters::construct_book_routes(db))
  .run(([127, 0, 0, 1], 3000))
  .await;
```

Here, we're telling the warp server what our routes are, and passing along the in-memory DB we've created.

Moving on to the next function:

```rust
  /// GET /books
  pub fn route_get_books(
  db: Db,
  ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
    warp::path!("books")
      .and(warp::get())
      .and(with_db(db))
      .and_then(handlers::get_books)
  }
```

We can ignore the function signature, as that's largely Warp specific requirements. Instead, let's look at the function line by line:

- We're creating a path called /books

- This path responds to GET requests

- It makes use of the database we're passing it

- And the actual logic is stored in a to-be-written function called get_books, within the handler's namespace

The other two routes define POST and DELETE, which follow a very similar pattern. Let's move on to the logical implementation:

```rust
mod handlers {
  use super::Db;
  use super::Book;
  use std::convert::Infallible;
  use warp::http::StatusCode;
    
  pub async fn get_books(db: Db) -> Result<impl warp::Reply, Infallible> {
    let books = db.lock().await;
    let books: Vec<Book> = books.clone();
    Ok(warp::reply::json(&books))
  }
    
  pub async fn create_book(
    book: Book,
    db: Db,
  ) -> Result<impl warp::Reply, Infallible> {
    let mut books = db.lock().await;
    
    books.push(book);
    
    Ok(StatusCode::CREATED)
  }
    
  pub async fn delete_book(
    id: u64,
    db: Db) -> Result<impl warp::Reply, Infallible> {
    let mut books = db.lock().await;
    
    let mut iter = 0;
    let len = books.len();
    books.retain(|_book| {
    let mut keep = true;
    if iter == id {
      iter += 1;
      keep = false;
    }
    iter += 1;
    keep
  });
    
    // If the vec is smaller, we found and deleted a book!
    let deleted = books.len() != len;
    
    if deleted {
    // respond with a `204 No Content`, which means successful,
      Ok(StatusCode::NO_CONTENT)
    } else {
      Ok(StatusCode::NOT_FOUND)
    }
  }
}
```

These routes don't do much! The GET function prints a list of all the books available; the POST function takes a new book and adds it to the vector; and the DELETE function removes a book based on its index in the vector.

(See the end of the article for the GitHub containing all this code.)

Go ahead and type cargo run in the terminal. Your project will recompile, and when it's finished, go ahead and enter curl [http://localhost:3000/books][10] in another terminal window. You should see a list of your books, and you can note that the other HTTP verbs work, too!

## Dockerizing the Rust server

Now, we're ready to take this project and containerize it via [Docker][5]. Docker has evolved over the years to make this process extremely simple. The entire Dockerfile fits in less than a dozen lines of code:

```docker
# Using the Rust official image...
FROM rust:1.60

# Copy the files in your machine to the Docker image...
COPY ./ ./

# Build your program for release...
RUN cargo build --release

# And run the binary!
CMD ["./target/release/server"]
```

We'll need to build the Docker container, which we can run with this command:

```console
docker build -t server .
```

And finally, we'll need to start the Docker container, which can be done like this:

```console
docker run -p 3000:3000 --rm --name server_docker server*
```

If you haven't seen the command for running a Docker container, then it's worth pointing out several things about the CLI flags. First, we're exposing port 3000 in our container to our localhost, as 3000. We could change these values if there were port number conflicts between our host machine and the Docker container, however, in this tutorial, that's not necessary. We're also naming our Docker as server_docker. This will make it easier to distinguish between logs and other systems' processes.

After the Docker run command executes, try running the curl command again. You *might* see the following error:

```
curl: (7) Failed to connect to localhost
```

What does it mean? Well, when Docker launches the container, it assigns it its own IP address. And when the Rust server points to 127.0.0.1, it's opening a connection to *itself*, not the broader public world. The fix for this is to change the IP address used in our Rust code, from 127.0.0.1 to 0.0.0.0:

```rust
warp::serve(filters::construct_book_routes(db))
  .run(([0, 0, 0, 0], 3000))
  .await;
```

Stop the server by executing the `docker stop` command on your terminal. Then, rebuild and rerun the container. If you try the curl command again, you should see the API working as expected!

## Deploying to Oracle Cloud Infrastructure (OCI)

At last, we reach the end of our tutorial: hosting our wonderful API online so that it's available across the internet. This is the easy part!

In order for the OCI to load your Docker image, you will first need to push it to the Oracle Container Registry. You'll first need to know your Docker container's image ID to do that. Run the following command to get that information:

docker images

You should see a list like the following:

```console
REPOSITORY TAG IMAGE ID CREATED SIZE

server latest 8f2569fb8987 25 hours ago 2.83GB
```

Take note of that image ID; we will use it when uploading the image to the Oracle Cloud Infrastructure.

Next, follow [these steps][11] to learn more about performing the following actions:

- `docker login $REGION_KEY.ocir.io`, which will log you into the Oracle Cloud Infrastructure Registry region you're using. Note that `$REGION_KEY` is determined by whichever region your account is using; see [this list][12] for the key which matches your region.

- When prompted, your username is in the format of `<tenancy_name>/<username>`. The tenancy name can be found under the Tenancy Details section of your administrative profile.

- Next, type `docker tag $IMAGE_ID $REGION_KEY.ocir.io/$TENANCY_NAME/server:latest`, where:

    - `$IMAGE_ID` is the image ID provided by Docker. (In this example, it's 8f2569fb8987.)

    - `$REGION_KEY` and `$TENANCY_NAME` are the same values provided earlier to log in.

- Finally, type `docker push $REGION_KEY.ocir.io/$TENANCY_NAME/server:latest`

Our server image has now been uploaded onto the Oracle Cloud Infrastructure Container Registry; the final step is to instruct your Oracle Cloud service to pull that image and make use of it. We could do the longer process of [setting up Kubernetes][13], but for such a small app, we can move much quicker if we simply load the image onto the VM directly.

Let's go ahead and create an OCI Compute instance on which to run our container. Refer to [the documentation here][14] to learn more about how to do so...be sure to create your Virtual Cloud Network (VCN) with at least one public subnet (hint: the VCN Wizard is a cinch). Be sure to download your SSH private key and take note of your public IP address.

After the instance is provisioned, we can pull our Docker image onto it. [Follow these directions to learn how to SSH into your VM instance][15].

Note that you may need to install Docker on your instance. You can verify whether this is required (or not) by entering the commands from [this guide][16] into your instance. Simply checking via the docker version command is enough to confirm Docker's presence:

```console
$ docker version
Emulate Docker CLI using podman. Create /etc/containers/nodocker to quiet msg. 

Client: Podman Engine
Version: 4.1.1
API Version: 4.1.1
Go Version: go1.17.12
Built: Thu Aug 4 02:48:00 2022
OS/Arch: linux/arm64                                                           
```

With Docker installed, we can pull our image from the Oracle Cloud Infrastructure Registry. First, log in to the OCI Registry using the same credentials as before:

```console
$ docker login $REGION_KEY.ocir.io
```

Then, pull the image using the tag identifier which was created:

```console
docker pull $REGION_KEY.ocir.io/$TENANCY_NAME/server:latest
```

Finally, we will need to make one essential security change, which is opening up a single network port to our machine so that the app is publicly accessible. To do that, you'll need to [set up an Ingress rule][17] and point it to port 3000 (HINT: this is done in the Networking configuration, within the VCN previously created). Here's a final screenshot of what setting up the Ingress rule looks like:

![][18]

Now that we've opened a rule on our network to allow ingress traffic over port 3000, we just need to open port 3000 in our local firewall to allow traffic through; run these two commands on the VM to do so:

```console
$ sudo firewall-cmd --permanent --zone=public --add-port=3000/tcp
$ sudo firewall-cmd --reload
```

Once that's finished, we can run the Docker image with the same command we used when running it on our development machine:

```console
docker run -d -p 3000:3000 --name server_docker $REGION_KEY.ocir.io/$TENANCY_NAME/server:latest
```

Voila! You can now call `curl http://$PUBLIC_IP_ADDRESS/books` and query the API, just like we did locally! Notice that we didn't need to install Rust or copy over any packages; that was all taken care of by Docker.

## Learning more

We've only scratched the surface of the features OCI offers for containerized applications. There are many more features catered to modern DevOps practices, including:

- Reliable database uptime and migrations
- Observability and monitoring
- Security and app isolation

The speed and performance capabilities of Rust are also paired nicely with the availability and response speeds which are provided to apps running on OCI. It's a win-win for dev, ops, and everything in between.

All the code used in this post can be found in [this gist][20]. For more information on how OCI can help you, be sure to check out [our docs][21]!

  [1]: https://blog.cloudflare.com/workers-rust-sdk/
  [2]: https://engineering.fb.com/2021/04/29/developer-tools/rust/
  [3]: https://discord.com/blog/why-discord-is-switching-from-go-to-rust
  [package ecosystems]: https://crates.io/
  [4]: https://rustup.rs
  [5]: https://www.docker.com
  [6]: https://www.oracle.com/cloud/free/?source=CloudFree_CTA1_Default&intcmp=CloudFree_CTA1_Default
  [7]: https://crates.io
  [8]: https://github.com/seanmonstar/warp
  [9]: http://127.0.0.1:3000
  [10]: http://localhost:3000/books
  [11]: https://docs.oracle.com/en/solutions/build-rest-java-application-with-oke/deploy-application-oracle-cloud.html#GUID-ED3E352E-F399-40A3-9530-6E436D99D28C
  [12]: https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm
  [13]: https://docs.oracle.com/en/solutions/build-rest-java-application-with-oke/deploy-your-application-kubernetes1.html#GUID-14EF66C9-3246-4478-B76C-5BF4031A9A8C
  [14]: https://docs.oracle.com/en/learn/lab_compute_instance/#create-a-web-server-on-a-compute-instance-1
  [15]: https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/accessinginstance.htm
  [16]: https://docs.oracle.com/en-us/iaas/Content/Functions/Tasks/functionsinstalldocker.htm
  [17]: https://docs.oracle.com/en-us/iaas/mysql-database/doc/adding-ingress-rules.html
  [18]: media/image1.jpg
  [20]: https://gist.github.com/gjtorikian/8dc63f63291889ad8d95b46ff8e441df
  [21]: https://docs.oracle.com/en-us/iaas/Content/GSG/Concepts/baremetalintro.htm
