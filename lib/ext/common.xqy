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

module namespace common = "http://superiorautomaticdictionary.com/ext/common";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace search="http://marklogic.com/appservices/search";

declare default function namespace "http://www.w3.org/2005/xpath-functions";



declare variable $common:mapping := map:new((
  map:entry("cc", "http://creativecommons.org/ns#"),
  map:entry("dc", "http://purl.org/dc/terms/"),
  map:entry("foaf", "http://xmlns.com/foaf/0.1/"),
  map:entry("media", "http://search.yahoo.com/searchmonkey/media/"),
  map:entry("owl", "http://www.w3.org/2002/07/owl#"),
  map:entry("rdf", "http://www.w3.org/1999/02/22-rdf-syntax-ns#"),
  map:entry("rdfs", "http://www.w3.org/2000/01/rdf-schema#"),
  map:entry("skos", "http://www.w3.org/2004/02/skos/core#"),
  map:entry("vcard", "http://www.w3.org/2006/vcard/ns#"),
  map:entry("void", "http://rdfs.org/ns/void#"),
  map:entry("xhtml", "http://www.w3.org/1999/xhtml#"),
  map:entry("xs","http://www.w3.org/2001/XMLSchema#"),
  map:entry("", "http://superiorautomaticdictionary.com/posts/"),
  map:entry("t", "http://superiorautomaticdictionary.com/terms/"),
  map:entry("meta", "http://superiorautomaticdictionary.com/meta/")));

declare variable $common:collation := "http://marklogic.com/collation/en/S1/T00BB/AS";
(: given triple XML and a title, make HTML representation :)

declare private function common:make-href(
    $h1 as xs:string,
    $t as sem:triple,
    $accessor as function(*),
    $tab as xs:string
) as attribute(href)
{
    attribute href { 
        concat("?rdf-uri=", 
        encode-for-uri($accessor($t)), 
        "&amp;h1=", 
        $h1,
        "&amp;tab=",
        $tab) 
    }
};

declare private function common:make-anchor(
    $h1 as xs:string,
    $t as sem:triple,
    $accessor as function(*)
) as element(html:a)
{
    element html:a {
        common:make-href($h1, $t, $accessor, "metadata"),
        text {sem:curie-shorten($accessor($t), $common:mapping)}
    }
};

declare function common:format-triples($triples, $h1) 
{
    element html:div {
        attribute id {"docmeta"},
        element html:pre {
            let $subjects := count(distinct-values($triples/sem:subject))
            for $triple at $index in $triples
            return 
                let $t := sem:triple($triple)
                return
                element html:span {
                    if ($subjects eq 1 and $index gt 1)
                    then 
                        "&nbsp;&nbsp;"
                    else common:make-anchor($h1, $t, sem:triple-subject#1),
                    text {" "},
                    element html:a {
                        attribute href { concat("?rdf-uri=", encode-for-uri($triple/sem:predicate), "&amp;h1=", $h1, "&amp;tab=metadata") },
                        text {sem:curie-shorten($triple/sem:predicate, $common:mapping)}
                    },
                    text { " " },
                    if (sem:triple-object($t) instance of sem:iri)
                    then common:make-anchor($h1, $t, sem:triple-object#1)
                    else text {concat('"', $triple/sem:object/string(), '"') },
                    text { ".  " },
                    element html:a {
                        common:make-href(encode-for-uri(
                            replace(sem:triple-subject($t),"http://superiorautomaticdictionary.com/posts/", "")), $t, sem:triple-subject#1, "article"),
                        text { "->" }
                    },
                    text {"&#10;" }
                }
        }
    }
};

declare function common:turtle-prefixes() {
    map:keys($common:mapping) ! function($k) { 
        concat("@prefix ",
        $k,
        ": <",
        map:get($common:mapping, $k),
        "> . &#10;")
    }(.)
};

declare function common:sparql-prefixes() {
    string-join(
        map:keys($common:mapping) ! function($k) { 
            concat("prefix ",
            $k,
            ": <",
            map:get($common:mapping, $k),
            "> &#10;")
        }(.),
        "")
};
