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
 : Ingestion transform for posts into Richter
 : @author Charles Greer
 :)

module namespace ingest = "http://marklogic.com/rest-api/transform/ingest";
declare namespace html = "http://www.w3.org/1999/xhtml";

import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare function ingest:transform(
  $context as map:map,
  $params as map:map,
  $content as document-node())
as document-node() {
    let $root := $content/node()
    let $turtle := $root/turtle/string()
    let $prefixes := "
        @prefix : <http://superiorautomaticdictionary.com/posts/> .
        @prefix t: <http://superiorautomaticdictionary.com/terms/> .
        @prefix meta: <http://superiorautomaticdictionary.com/meta/> .
        @prefix dc: <http://purl.org/dc/terms/> .
        @prefix xs: <http://www.w3.org/2001/XMLSchema#> .
        @prefix foaf: <http://xmlns.com/foaf/0.1/> .
        @prefix owl: <http://www.w3.org/2002/07/owl#> .
        @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
        "
    let $triples := sem:rdf-parse($prefixes || $turtle, "turtle")
    let $title := $root/html:html/html:h1
    let $clean-collections := 
        xdmp:document-remove-collections(
            cts:search(
                collection("CURRENT"), 
                cts:element-query(xs:QName("html:h1"), 
                cts:word-query($title)))/base-uri(), 
            "CURRENT")
    return document {
        element {node-name($root)} {
            attribute created { current-dateTime() },
            $triples,
            $root/* except $root/turtle 
        }
    }
};
