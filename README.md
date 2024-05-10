# 📊 3tx PowerBI Example

An example Power BI `.pbix` file that connects to the 3tx platform and fetches data for you to perform analysis upon. It is expected that a technical person who is more familiar with Power BI prepares a dashboard for the intended audience since some setup is required.

![screenie](3tx-pbi-example.jpg)

## 🚨 Work in Progress

Please be aware that this is currently an example, and is designed to showcase using the 3tx API for Power BI. You will need knowledge of Power BI to make full use of this early proof of concept.

## 👏 Getting Started

![parameters](3tx-pbi-parameters.png)

1. You will need to have an account inside 3tx, with sufficient permissions to access the API. Please talk to us if you don't understand what this means. You will end up with a username and password where the username is likely an email address.
2. You will need to enter the `parameters` section inside the example `.pbix` and type your credentials into the correct parameters.
3. You will need to set your `client id` and `organisation`. In the description for the `client id`, you will find the `client id` for both **production** and **UAT**. The organisation will be as it appears in the URL when you log into the web application.
4. Refresh all your data sources. Depending on the amount of workers and their attestations, you may find this process takes a few minutes. Bear with it, remember that we are pulling records page by page.

![pagination](3ts-pbi-pagination.png)

## 🧱 Structure

The file uses the Power Query Formula Language "M".

- We use your provided credentials to get a security token
- We use that token to fetch a page of results from the API
- We loop over the API fetching all the results we can
- We store the results for you to query.

The example file contains some simple vanity metrics to get started, but they are by no means useful and it is suggested you delete them and use the data for your own needs. 

## 🔋 Power Query Formula Language

> 🧑‍🏫  [Quick tour of the Power Query M formula language
](https://learn.microsoft.com/en-us/powerquery-m/quick-tour-of-the-power-query-m-formula-language)

The Power Query Formula Language (informally known as "M") is a powerful mashup query language optimized for building queries that mashup data. It is a functional, case-sensitive language similar to F#. M will likely be the first language that new users use although it is unlikely that they are aware of the fact that they are using it. The reason is that when users are importing data into their data model, which is generally the first step in using Power BI Designer, the queries are most likely using M in the background. However, the Query Editor provides a powerful graphical interface that allows users to perform complex data mashups without ever having to look at the M code that the Query Editor is building behind the scenes.

### API Function Example

In this example, we use `Web.Contents` to call the API after we prepare our token in the header.

```fs
(paginationPage as number)=>
let
    apiurl="https://uat.3tplatform.com",
    PaginationPage = Text.From(paginationPage),
    headers = [
        organisation=TttxOrganisation,
        Authorization="Bearer " & GetCognitoToken
    ],
    options = [
        RelativePath = "/v2/workforce",
        Headers = headers,
        Query=[page=PaginationPage]
    ],
    response = Web.Contents(apiurl, options),
    #"Workforce" = Json.Document(response),
    data = #"Workforce"[data]
in
    data
```


### Pagination Example

This example uses our API call function to paginate results until there are no more to fetch, then returns them all as a single set.

```fs
let
    Source = List.Generate(()=>
        [Result = try fWorkforce(1) otherwise null, Page = 1],
        each [Result] <> null,
        each [Result = try fWorkforce([Page]+1) otherwise null, Page=[Page]+1],
        each [Result]
    ),
    #"Workforce" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
in
    #"Workforce"
```
