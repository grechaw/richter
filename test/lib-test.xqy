xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
declare namespace results = "http://www.w3.org/2005/sparql-results#";
declare namespace html = "http://www.w3.org/1999/xhtml";

import module namespace lib = "http://superiorautomaticdictionary.com/lib" at "../lib.xqy";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";


declare %test:case function setup-works ()
{
    let $answer := lib:do-http("GET", "http://localhost:8007/v1/config/transforms")/node()
    return assert:equal(<rapi:transforms xmlns:rapi="http://marklogic.com/rest-api">
      <rapi:transform>
	<rapi:name>concordance</rapi:name>
	<rapi:source-format>xquery</rapi:source-format>
	<rapi:transform-parameters></rapi:transform-parameters>
	<rapi:transform-source>/v1/config/transforms/concordance</rapi:transform-source>
      </rapi:transform>
      <rapi:transform>
	<rapi:name>docout</rapi:name>
	<rapi:source-format>xquery</rapi:source-format>
	<rapi:transform-parameters></rapi:transform-parameters>
	<rapi:transform-source>/v1/config/transforms/docout</rapi:transform-source>
      </rapi:transform>
      <rapi:transform>
	<rapi:name>ingest</rapi:name>
	<rapi:source-format>xquery</rapi:source-format>
	<rapi:transform-parameters></rapi:transform-parameters>
	<rapi:transform-source>/v1/config/transforms/ingest</rapi:transform-source>
      </rapi:transform>
    </rapi:transforms>, $answer, "Unexpected transform configs")
};


declare function post($filename) {
    lib:do-http("POST", $lib:docs-uri || "?extension=xml&amp;directory=/posts&amp;transform=ingest&amp;collection=CURRENT", xs:string (xdmp:filesystem-file(xdmp:modules-root() || "test/" || $filename)), 
     <options xmlns="xdmp:http">
       <authentication method="digest">
         <username>rest-admin</username>
         <password>x</password>
       </authentication>
       <headers>
           <content-type>application/xml</content-type>
       </headers>
     </options>)
};

declare %test:case function test-latest()
{
    let $post-future := post("test-post.xml")
    let $latest := lib:latest()
    return assert:equal(node-name($latest), xs:QName("html:ul"))
};

declare %test:case function test-terms()
{
    let $terms := lib:terms()
    return assert:equal(($terms//html:li/html:a/string())[1], "architecture")
};


declare %test:case function test-concordance()
{
    let $concordance := lib:concordance("architecture")
    return assert:equal(($concordance//html:a/string())[1], "Requirements")
};

