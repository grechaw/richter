xquery version "1.0-ml";

(:
 : Copyright 2013 Charles Greer
 : 
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 : 
 : http://www.apache.org/licenses/LICENSE-2.0
 : 
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :
 :)

(:~
 : Main module for Richter client application
 : @author Charles Greer
 :)

import module namespace rest = "http://marklogic.com/appservices/rest" 
  at "/MarkLogic/appservices/utils/rest.xqy";
import module namespace lib = "http://superiorautomaticdictionary.com/lib"
  at "lib.xqy";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
import module namespace common = "http://superiorautomaticdictionary.com/ext/common" at "/lib/ext/common.xqy";

declare namespace html="http://www.w3.org/1999/xhtml";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare variable $local:default-uri := "http://myomy";

declare option xdmp:mapping "false";

declare function local:app-rule() {
    <rest:request user-params="allow">
        <rest:param name="q" required="false"/>
        <rest:param name="h1" required="false"/>
        <rest:param name="doc" required="false"/>
        <rest:param name="metadata" required="false"/>
        <rest:http method="GET"/>
    </rest:request>
};

declare function local:html-page(
    $params as map:map
) as element(html:html)
{
    let $q := (map:get($params, "q"),"dictionary")[1]
    let $title := (map:get($params, "h1"), "Dictionary")[1]
    let $docuri := map:get($params, "doc")
    let $rdf-uri := (map:get($params, "rdf-uri"), $local:default-uri)[1]
    return
    <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" ></meta>
            <meta name="keywords" content=""></meta>
            <meta name="description" content=""></meta>
            <title>Richter</title>
            <link rel="stylesheet" href="stylesheets/base.css"/>
            <link rel="stylesheet" href="stylesheets/skeleton.css"/>
            <link rel="stylesheet" href="stylesheets/layout.css"/>
            <script src="//ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js"></script>
            <script src="richter.js"></script>
        </head>
        <body>
            <div class="container">
                <div class="sixteen columns">
                    <h1><a href="/">Richter</a></h1>
                    <p>A MarkLogic-backed publishing system for some sort of <a href="?q=dictionary&amp;h1=Richter">dictionary</a> by Charles Greer</p>
                </div>

                <div id="header">
                    <ul class="tabs">
                        <li><a href="#latest">What's New</a></li>
                        <li><a href="#terms">Terms</a></li> 
                        <li><a href="#concordance">"{$q}"</a></li>
                        <li><a href="#article"><em>{$title}</em></a></li>
                        <li><a href="#metadata">{sem:curie-shorten(sem:iri($rdf-uri), $common:mapping)}</a></li> 
                        <li><a href="#diagnostics">Diagnostics</a></li> 
                    </ul>
                </div>
                
                <div id="latest" class="content">
                    {lib:latest()}
                </div>

                <div id="terms" class="content">
                    { lib:terms() }
                </div>

                <div id="article" class="content">
                {
                    if ($docuri)
                    then lib:doc($docuri)
                    else lib:doc-title($title) 
                }
                </div>

                <div id="concordance" class="content">
                    { lib:concordance($q) }
                </div>

                <div id="metadata" class="content">
                    { lib:metadata($rdf-uri, ($title, "")[1]) }
                </div>


                <div id="diagnostics" class="content">
                <pre> 
                    q: { map:get($params, "q") }
                    h1: { (map:get($params, "h1"), "Default")[1] }
                    doc-uri: { map:get($params, "doc") }
                    rdf-uri: {(map:get($params, "rdf-uri"), $local:default-uri)[1]}
                </pre>
                </div>
        </div>
    </body>
</html>
};

let $params := rest:process-request(local:app-rule())
return
    (
        xdmp:set-response-content-type("text/html"),
        local:html-page($params)
    )
