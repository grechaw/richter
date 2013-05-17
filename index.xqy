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

declare namespace html="http://www.w3.org/1999/xhtml";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

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
    let $q := map:get($params, "q")
    let $title := map:get($params, "h1")
    let $docuri := map:get($params, "doc")
    let $rdf-uri := map:get($params, "rdf-uri")
    return
    <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" ></meta>
            <meta name="keywords" content=""></meta>
            <meta name="description" content=""></meta>
            <title>Richter</title>
            <link rel="stylesheet" type="text/css" href="base.css"></link>
        </head>
        <body>
            <div id="top">

                <h1><a href="/">Richter</a></h1>
                <p>A MarkLogic-backed publishing system for some sort of <a href="?q=dictionary&amp;h1=Richter">dictionary</a> by Charles Greer</p>
            </div>

        <div id="left">
        {
            if ($title) 
            then lib:doc-title($title) 
            else if ($docuri)
            then lib:doc($docuri)
            else ( 
                 <h1>What's New</h1>, 
                 <img src="images/stoetz.png" id="bg"/>, 
                 lib:latest())
        }
        </div>


        <div id="right">
        {
            if ($q)
            then
                (
                <h1>Concordance all about "{$q}"</h1>,
                lib:concordance($q))
            else if ($rdf-uri)
            then 
                ( 
                <p>Facts about &lt;{$rdf-uri}&gt;</p>, 
                lib:metadata($rdf-uri, ($title, "")[1])
                )
            else
                (
                <p>Metadata about Richter</p>,
                lib:metadata("http://superiorautomaticdictionary.com/posts/richter", ($title, "")[1]),
                <p>A list of terms:</p>, 
                lib:terms()
                )
        }
        </div>
        <div id="tweet">
<a href="https://twitter.com/share" class="twitter-share-button" data-count="none" data-hashtags="superiorautomaticdictionary" data-dnt="true">Tweet</a>
<script>!function(d,s,id){{var js,fjs=d.getElementsByTagName(s)[0],p=/^http:/.test(d.location)?'http':'https';if(!d.getElementById(id)){{js=d.createElement(s);js.id=id;js.src=p+'://platform.twitter.com/widgets.js';fjs.parentNode.insertBefore(js,fjs);}}}}(document, 'script', 'twitter-wjs');</script>
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
