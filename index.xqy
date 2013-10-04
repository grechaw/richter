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

declare option xdmp:mapping "false";

declare function local:app-rule() {
    <rest:request user-params="allow">
        <rest:param name="q" required="false"/>
        <rest:param name="title" required="false"/>
        <rest:param name="doc" required="false"/>
        <rest:param name="metadata" required="false"/>
        <rest:param name="reply-to" required="false"/>
        <rest:http method="GET"/>
    </rest:request>
};

declare function local:html-page(
    $params as map:map
) as element(html:html)
{
    let $q := map:get($params, "q")
    let $title := map:get($params, "title")
    let $docuri := map:get($params, "doc")
    let $rdf-uri := map:get($params, "rdf-uri")
    let $reply-to := map:get($params, "reply-to")
    return
    <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" ></meta>
            <meta name="keywords" content=""></meta>
            <meta name="description" content=""></meta>
            <title>Media Literacy</title>
            <link rel="stylesheet" href="stylesheets/base.css"/>
            <link rel="stylesheet" href="stylesheets/skeleton.css"/>
            <link rel="stylesheet" href="stylesheets/layout.css"/>
        </head>
        <body>
            <div class="container">
                <div class="sixteen columns">
                    <h1><a href="/">Forum of Harmonicatude</a></h1>
                    <p>Here is where we discuss and record harmonica stuff.</p>
                </div>

            <div class="ten columns alpha">
        {
            if ($title) 
            then (lib:doc-title($title), <a href="{lib:reply-link($title)}">Reply</a>)
            else if ($docuri)
            then lib:doc($docuri)
            else ( 
                 <h3>What's New</h3>, 
                 <img src="images/media.jpg" id="bg"/>, 
                 lib:latest())
        }
        </div>

        <div class="six columns omega">
        {
            if ($q)
            then
                (
                <h3>Hypertext "{$q}"</h3>,
                lib:concordance($q)
                )
                else 
                    if ($rdf-uri)
                    then
                        (
                            <h3>{sem:curie-shorten(sem:iri($rdf-uri), $common:mapping)}</h3>, 
                            lib:metadata($rdf-uri, ($title, "")[1])
                        )
                    else
                        (
                            <h3>Terms:</h3>, 
                            lib:terms()
                        )
        }
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
