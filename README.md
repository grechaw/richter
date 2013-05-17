richter
=======

A personal data and content publishing platform.
and experimental MarkLogic client and server REST API application

Charles Greer
@grechaw

Here's the start-to-end quickstart:

1.  Using the steps in the installation guide, install and setup MarkLogic 7.
1.  Clone this project from github.
1.  Edit config.ttl to configure the application.  "homeDirectory" is the only property you'll probably need to edit.
1.  Browse to http://{host}:8000/qconsole
1.  From the "Workspace" pull-down menu on the right, import the file setup.xml" 
1.  Run the first query in the workspace, "Bootstrap Client."
1.  Refresh the qconsole page to pick up your new appsever.  
1.  Select it: "Documents - /your/app" from the Content Source drop-down.
1.  Run the other three queries in the workspace, in order from top to bottom:
 - bootstrap REST
 - configure REST
 - Install REST extensions
1.  Navigate to 'http://localhost:8040/


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


