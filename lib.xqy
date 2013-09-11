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
 : Catch-all library module for Richter client application
 : @author Charles Greer
 :)

module namespace lib = "http://superiorautomaticdictionary.com/lib";

import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
import module namespace common = "http://superiorautomaticdictionary.com/ext/common" at "lib/ext/common.xqy";

declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";
declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare namespace search = "http://marklogic.com/appservices/search";
declare namespace rapi = "http://marklogic.com/rest-api";

declare variable $collation := "http://marklogic.com/collation/en/S1/AS/T00BB";

declare option xdmp:mapping "false";


declare variable $lib:config := "";


(: endpoints :)
declare variable $search-uri := "http://localhost:8007/v1/search";
declare variable $docs-uri := "http://localhost:8007/v1/documents";
declare variable $values-uri := "http://localhost:8007/v1/values";
declare variable $sparql-uri := "http://localhost:8007/v1/graphs/sparql";
declare variable $things-uri := "http://localhost:8007/v1/graphs/things";

(: authentication :)
declare variable $rest-user := "richter-app-user";
declare variable $rest-passwd := "obscure-password";

declare variable $auth :=
         <authentication method="digest" xmlns="xdmp:http">
             <username>{$rest-user}</username>
             <password>{$rest-passwd}</password>
         </authentication>;

(: stock http headers typical http interaction :)
declare variable $headers :=
         <headers xmlns="xdmp:http">
             <content-type>application/xml</content-type>
             <accept>application/xml</accept>
         </headers>;

(: function pointers to MarkLogic http methods :)
declare variable $lib:methods := map:new((
    map:entry("GET", function($a1, $a2) { xdmp:http-get($a1, $a2)}),
    map:entry("POST", function($a1, $a2, $a3) { xdmp:http-post($a1, $a2, $a3)}),
    map:entry("PUT", function($a1, $a2, $a3) { xdmp:http-put($a1, $a2, $a3)}),
    map:entry("DELETE", function($a1, $a2) { xdmp:http-delete($a1, $a2)}),
    map:entry("HEAD", function($a1, $a2) { xdmp:http-head($a1, $a2)})));

declare function lib:do-http($verb, $uri)
{
    lib:do-http($verb, $uri, ())
};

(:
 : Privileges this application to do http calls 
 : on behalf of user (non-authenticated read-only proxy)
 :)
declare function lib:do-http(
$verb, $uri, $body) {
    lib:do-http($verb, $uri, $body, ())
};

declare function lib:do-http(
$verb, $uri, $body, $options)
{
    let $sec := xdmp:security-assert("http://marklogic.com/xdmp/privileges/rest-reader", "execute")
    let $method := map:get($lib:methods, $verb)
    let $options := ($options, <options xmlns="xdmp:http">{$auth}{$headers}</options>)[1]
    let $body := if ($body) then xdmp:quote($body) else ()
    let $response := 
        if (fn:empty($body))
        then $method($uri, $options)[2]
        else $method($uri, $options, text { $body })[2]
    return
        (xdmp:log(("RESPONSE",$response)),
        if ($response/node() instance of element(rapi:error))
        then lib:error($response)
        else $response)
};

declare function lib:do-sparql($sparql) {
    lib:do-http("GET",
        concat($lib:sparql-uri, "?query=", encode-for-uri(common:sparql-prefixes() || $sparql)),
        (),
        <options xmlns="xdmp:http">{$auth}<headers><accept>application/sparql-results+xml</accept></headers></options>)[1]
};

declare function lib:configure()
{
    let $f := xdmp:filesystem-file(xdmp:modules-root() || "config.ttl")
    let $rdf := xdmp:turtle($f)
    return 
        xdmp:set($lib:config, $rdf)
};
(: given a set of triples extracts objects for property name X :)
declare function lib:get-property($propertyName) {
  map:get(
      sem:sparql-triples(
          "prefix : <http://superiorautomaticdictionary.com/> 
           select ?o where { ?s :" || $propertyName || " ?o}", $lib:config), "o")
};


declare function lib:metadata($rdf-uri as xs:string, $h1)
{
    let $results := lib:do-http("GET", 
        concat($lib:things-uri, "?iri=", encode-for-uri($rdf-uri)), 
        (),
        <options xmlns="xdmp:http">{$auth}<headers><accept>text/plain</accept></headers></options>)[1]
        let $rdf := <a>{xdmp:nquad($results)}</a>
        return common:format-triples($rdf/*, $h1)
};

declare function lib:terms() {
    let $terms := lib:do-http("POST", 
        $values-uri || '/terms',
        <search xmlns="http://marklogic.com/appservices/search">
            <query>
                <collection-query>
                    <uri>CURRENT</uri>
                </collection-query>
            </query>
            <options>
                <values name="terms">
                    <range type="xs:string" collation="{$common:collation}">
                        <element ns="http://www.w3.org/1999/xhtml" name="a"/>
                    </range>
                </values>
                <debug>true</debug>
            </options>
    </search>)
    return 
    <ul xmlns="http://www.w3.org/1999/xhtml">
    {
        for $result in $terms//search:distinct-value
        return
            <li>
                <a href="?q={encode-for-uri($result)}">
                    {$result}
                </a>
            </li>
    }
    </ul>
};

declare function lib:latest() {
    let $articles := lib:do-sparql("
select ?title ?pubDate from <CURRENT>
        where { ?p a meta:Post ; dc:title ?title ; dc:issued ?pubDate .}
       order by desc(?pubDate)")
    return 
    <ul xmlns="http://www.w3.org/1999/xhtml">
    {
        for $result in $articles//sr:result
        let $title := $result//sr:binding[@name="title"]/sr:literal/string()
        let $pubDate := $result//sr:binding[@name="pubDate"]/sr:literal/string()
        return
            <li>
            <a href="?q={encode-for-uri($title)}&amp;h1={encode-for-uri($title)}">
                {$pubDate}&nbsp;{$title} 
                </a>
            </li>
    }
    </ul>
};


declare function lib:doc($docuri) {
    lib:do-http("GET", concat($docs-uri, "?uri=", encode-for-uri($docuri), "&amp;transform=docout"))
};

declare function lib:doc-title($title) {
    let $doc := lib:do-http("POST", 
        $search-uri || '?transform=docout', 
        <search xmlns="http://marklogic.com/appservices/search">
            <qtext>"{$title}"</qtext>
            <query>
                <collection-query>
                    <uri>CURRENT</uri>
                </collection-query>
            </query>
            <options>
                <debug>true</debug>
                <transform-results apply="raw"/>
                <page-length>1</page-length>
            </options>
    </search>)
    return $doc
};

declare function lib:concordance($term) {
    lib:do-http("POST",
        $search-uri || "?transform=concordance",
        <search xmlns="http://marklogic.com/appservices/search">
            <query>
                <and-query>
                    <element-constraint-query>
                        <constraint-name>posts</constraint-name>
                        <term-query>
                            <text>{lower-case($term)}</text>
                        </term-query>
                    </element-constraint-query>
                    <collection-query>
                        <uri>CURRENT</uri>
                    </collection-query>
                </and-query>
            </query>
            <options>
                <constraint name="posts">
                    <element-query ns="http://www.w3.org/1999/xhtml" name="html"/>
                </constraint>
                <extract-metadata>
                    <qname elem-ns="http://www.w3.org/1999/xhtml" elem-name="h1"/>
                </extract-metadata>
                <page-length>200</page-length>
                <debug>true</debug>
                <return-query>true</return-query>
            </options>
    </search>)
};

declare function lib:error($e) {
    <pre xmlns="http://www.w3.org/1999/xhtml">
    {xdmp:quote($e, 
        <options xmlns="xdmp:quote">
            <indent>yes</indent>
            <indent-untyped>yes</indent-untyped>
        </options>)}
    </pre>
};
