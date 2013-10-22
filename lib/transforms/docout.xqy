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
 : A transform library for displaying Richter artifacts as HTML 
 :)
module namespace docout = "http://marklogic.com/rest-api/transform/docout";
import module namespace common = "http://superiorautomaticdictionary.com/ext/common" at "/ext/common.xqy";

import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare namespace results = "http://www.w3.org/2005/sparql-results#";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace search="http://marklogic.com/appservices/search";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare function docout:decorate(
    $nodes as node()*
) as node()*
{
    for $n in $nodes
    return
        typeswitch($n)
            case element(html:h1)
                return 
                    element html:h3 {
                        $n/@*,
                        element html:a {
                            attribute href { "?q=" || encode-for-uri($n/text()/string()) || "&amp;h1=" || $n//text()/string()},
                            docout:decorate($n/node() except $n/@*)
                        }
                    }
            case element(html:img)
                return 
                    if ($n/@id)
                    then $n
                    else element html:img {
                        $n/@*,
                        attribute id { "bg" }
                    }
            case element(html:a)
                return element html:a { 
                    attribute href { "?q=" || encode-for-uri($n/text()/string()) || "&amp;h1=" || $n/preceding::html:h1/text()/string()},
                    docout:decorate($n/node())}
            case element() 
                return element {node-name($n)} {
                    $n/@*,
                    docout:decorate($n/node())
                    }
            default return $n
};


declare function docout:transform(
  $context as map:map,
  $params as map:map,
  $content as document-node()
) as document-node() 
{
    let $termlist := cts:element-words(xs:QName("html:a"), "a", ("collation="||$common:collation))[not(. = ("a", "of", "the"))]
    let $root := if (node-name($content/node()) eq xs:QName("post"))
                    then $content
                 else $content//search:result
    let $triples := $root//sem:triple
    let $h1 := encode-for-uri( ($root//html:h1/string(.), "")[1] )
    let $sparql-results := if ($root//sparql)
                           then sem:query-results-serialize(
                               sem:sparql(common:sparql-prefixes() || ' ' || $root//sparql/text()))
                           else <results>"NO SPARQL"</results>
    let $decorated := docout:decorate( $root//html:html)
    return document {
        element html:div {
            element html:div {
                attribute class {"content"},
                attribute id { "article" },
                if (exists($decorated))
                then
                    cts:highlight(
                        $decorated,
                        cts:word-query($termlist), 
                        element html:a {
                            attribute href { "?q=" || encode-for-uri($cts:text) || "&amp;h1=" || $h1},
                            $cts:text
                         })
                else ()
            },
            element html:div {
                attribute id { "sparql" },
                element html:table {
                    element html:tr {
                        for $v in $sparql-results//results:variable/@name/data(.)
                        return element html:th {
                            $v
                        }
                    },
                    for $row in $sparql-results//results:result
                    return element html:tr {
                        for $binding in $row//results:binding
                        return element html:td {
                            if ($binding/results:uri)
                            then sem:curie-shorten($binding//text(), $common:mapping)
                            else $binding//text()
                        }
                    }
                }
            },
            element html:div {
                attribute class { "content" },
                attribute id { "docmeta" },
                element html:pre { common:format-triples($triples, $h1) } 
            }
        }
    }
};


