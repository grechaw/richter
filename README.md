richter
=======

A personal data and content publishing platform.
and experimental MarkLogic client and server REST API application

Charles Greer
@grechaw

Here's the start-to-end quickstart:

a. Using the steps in the installation guide, install and setup MarkLogic 7.
b. Clone this project from github.
c. Edit config.ttl to configure the application.  "homeDirectory" is the only
property you'll probably need to edit.
d. Browse to http://{host}:8000/qconsole
e. From the "Workspace" pull-down menu on the right, import the file 
 "setup.xml" 
f. Run the first query in the workspace, "Bootstrap Client."
g. Refresh the qconsole page to pick up your new appsever.  
h. Select it: "Documents - /your/app" from the Content Source drop-down.
i. Run the other three queries in the workspace, in order from top to bottom:
  - bootstrap REST
  - configure REST
  - Install REST extensions
j. Navigate to 'http://localhost:8040/


The point of Richter, aside from being moderately useful for myself, is to
provide an example of how to work with MarkLogic REST API and with MarkLogic
semantics.  The use case is simple, but illustrates some new and/or different
ways to approach XQuery and RDF architectures:

* Separating XQuery client application from the REST server (treat REST server like a database)
* How to parse turtle into triples
* Ho to run sparql queries
* How to implement and install transforms for documents and search results.
* Using dynamic string search and query options
* An out-of-band update strategy (method to interact with REST server directly)
* Self-contained bootstrapping  (via a query-console workspace)

Hope you enjoy it.


