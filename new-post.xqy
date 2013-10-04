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
import module namespace rest = "http://marklogic.com/appservices/rest" 
  at "/MarkLogic/appservices/utils/rest.xqy";
import module namespace lib = "http://superiorautomaticdictionary.com/lib"
  at "lib.xqy";

declare namespace html="http://www.w3.org/1999/xhtml";
declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare option xdmp:mapping "false";

declare function local:post-rule() {
    <rest:request user-params="forbid">
        <rest:param name="reply-to" required="false"/>
        <rest:param name="handle" required="true"/>
        <rest:param name="title" required="true"/>
        <rest:param name="postbody" required="true"/>
        <rest:http method="POST"/>
    </rest:request>
};

declare private function local:uriFromString(
    $string
) as xs:string
{
    replace($string, "[ \.]", "")
};

declare function local:submit-post(
    $params as map:map
) 
{
    let $handle := map:get($params, "handle")
    let $title := map:get($params, "title")
    let $post-title := local:uriFromString($title)
    let $post-body := map:get($params, "postbody")
    let $reply-to := map:get($params, "reply-to")
    let $reply-statement :=
            if (exists($reply-to)) then (" meta:reply-to " || $reply-to || " ; ") else "" 
    let $post-template-turtle :=
        xdmp:unquote(
            "<turtle><![CDATA[ "||
            ":"|| $post-title || " a meta:Post ; " ||
            'dc:title "' || $title ||'" ; '||
            'meta:handle "' || $handle || '" ; ' ||
            $reply-statement ||
            'dc:issued "' || current-date() || '"^^xs:date . ' ||
            ']]></turtle>')
    let $_ := xdmp:log(("TUR", $post-template-turtle))
    let $surrounded := replace($post-body, '"([^"]+)"', '<a xmlns="http://www.w3.org/1999/xhtml">$1</a>')
    let $post := 
        <post>
        {$post-template-turtle}
        <html xmlns="http://www.w3.org/1999/xhtml">
            <h1>{$title}</h1>
            <p>{xdmp:unquote("<post>" || $surrounded || "</post>")/*/node()}</p>
        </html>
        </post>
    return lib:new-post($post)
};

let $params := rest:process-request(local:post-rule())
return
    (
        xdmp:set-response-content-type("text/html"),
        local:submit-post($params),
        xdmp:redirect-response("/index.xqy?h1=" || map:get($params, "title"))
    )
