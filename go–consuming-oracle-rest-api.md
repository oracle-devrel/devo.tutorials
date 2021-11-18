---
title: GoLang–Consuming Oracle REST API from an Oracle Cloud Database 
parent: [tutorials]
toc: true
tags: 
  - oci
  - go
  - back-end
  - machine-learning
categories: [ai-ml]
date: 2021-11-18 19:42
description: Brendan Tierney shares a method to call an in-database machine learning model and then process the data it returns using GoLang.
author: 
    name: Brendan Tierney
---
Does anyone write code to access data in a database anymore (and by code I mean SQL)?  The answer to this question is "it depends," just like everything in IT.

Using REST APIs is very common for accessing and processing data with a database. For things like using an API to retrieve data, using a slightly different API to insert data, or using other typical REST functions to perform your typical CRUD operations, REST APIs allow developers to focus on writing efficient applications in a particular application instead of having to swap between their programming language and SQL. 

In the latter cases, most developers are not experts with SQL and don't necessarily know how to work efficiently with the data. Therefore, leave the SQL and procedural coding to those who are good at that, and then expose the data and their code using REST APIs. The end result is efficient SQL and database coding, in addition to efficient application coding. This is a win-win for everyone.

I’ve written before about creating REST APIs in an Oracle Cloud Database (DBaaS and Autonomous). In these writings I’ve shown how to use the in-database machine learning features, and how to use REST APIs to create an interface to machine learning models. These models can be used to score new data to make a machine learning prediction. The data being used for the prediction doesn’t have to exist in the database --- instead, the database is being used as a machine learning scoring engine, accessed using a REST API.

[Check out an article I wrote about this and creating a REST API for an in-database machine learning model, for Oracle Magazine.](https://blogs.oracle.com/oraclemagazine/post/rest-enabling-oracle-machine-learning-models)

In that article, I showed how easy it was to use the in-database machine model using Python.

Python has a huge fan and user base, but it can underperform as it's an interrupted language. Don’t get me wrong --- lots of work has gone into making Python more efficient. But in some scenarios, it just isn’t fast enough. In some scenarios, people will switch to languages which execute quicker, such as C, C++, Java, and GoLang.

Here is the GoLang code to call the in-database machine learning model and process the returned data.

```go
import (
    "bytes"
    "encoding/json"
    "fmt"
    "io/ioutil"
    "net/http"
    "os"
)

func main() {
    fmt.Println("---------------------------------------------------")
    fmt.Println("Starting Demo - Calling Oracle in-database ML Model")
    fmt.Println("")

    // Define variables for REST API and parameter for first prediction
    rest_api = "<full REST API>"

    // This wine is Bad
    a_country := "Portugal"
    a_province := "Douro"
    a_variety := "Portuguese Red"
    a_price := "30"

    // call the REST API adding in the parameters
    response, err := http.Get(rest_api +"/"+ a_country +"/"+ a_province +"/"+ a_variety +"/"+ a_price)
    if err != nil {
        // an error has occurred. Exit
        fmt.Printf("The HTTP request failed with error :: %s\n", err)
        os.Exit(1)
    } else {
        // we got data! Now extract it and print to screen
        responseData, _ := ioutil.ReadAll(response.Body)
        fmt.Println(string(responseData))
    }
    response.Body.Close()

    // Lets do call it again with a different set of parameters

    // This wine is Good - same details except the price is different
    a_price := "31"

    // call the REST API adding in the parameters
    response, err := http.Get(rest_api +"/"+ a_country +"/"+ a_province +"/"+ a_variety +"/"+ a_price)
    if err != nil {
        // an error has occurred. Exit
        fmt.Printf("The HTTP request failed with error :: %s\n", err)
        os.Exit(1)
    } else {
        responseData, _ := ioutil.ReadAll(response.Body)
        fmt.Println(string(responseData))
    }
    defer response.Body.Close()

    // All done! 
    fmt.Println("")
    fmt.Println("...Finished Demo ...")
    fmt.Println("---------------------------------------------------")
}
```
