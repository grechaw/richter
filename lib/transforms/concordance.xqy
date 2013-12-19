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
 : Transform module for displaying the word concordance for Richter.
 : @author Charles Greer
 :)

module namespace concordance = "http://marklogic.com/rest-api/transform/concordance";

declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace search = "http://marklogic.com/appservices/search";

(:
 : transforms a search result into html concordance for web page.
 : Relies on extract metadata option for sieve.
 :)
declare function concordance:transform(
  $context as map:map,
  $params as map:map,
  $content as document-node())
as document-node() {
    (: let $_ := xdmp:log($content)  :)
    let $root := $content/node()
    let $qtext := $root//cts:word-query/cts:text/string(.)
    return document {
        element html:dl {
            for $result in $root//search:result
            let $docuri := $result/@uri/data()
            for $match in $result/search:snippet/search:match
            let $title := $result/search:metadata/html:h1/string()
            return
                (
                element html:dt {
                    element html:a {
                        attribute href { "?q="|| $qtext || 
                                         "&amp;h1=" || $title ||
                                         "&amp;tab=article"},
                        text {$title}
                    }
                },
                element html:dd {
                    text {"..."},
                    for $node in $match/node()
                    return 
                        typeswitch ($node)
                            case element(search:highlight)
                                return <html:a href="?q={$qtext}&amp;h1={$title}&amp;tab=article">{$node/text()}</html:a>
                            default return $node,
                    text {"..."}
                }
                )
                (: , element html:li { xdmp:quote($root//search:report) } :)
        }
    }
};
