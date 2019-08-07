xquery version "3.1";

module namespace api="http://library.princeton.edu/apps/pulfa";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://library.princeton.edu/apps/pulfa/config" at "config.xqm";

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace rest = "http://exquery.org/ns/restxq" ;

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http = "http://expath.org/ns/http-client"; 
declare namespace ead="urn:isbn:1-931666-22-9";
declare namespace vc="http://www.w3.org/2006/vcard/ns#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare function local:repo-component($vcard as element()) 
as item()
{
 <repository>
   <id>{xs:string($vcard/@rdf:about)}</id>
   <label>{ xs:string($vcard/vc:fn)}</label>
 </repository>
};


declare function local:ead-struct($ead as element()) as element() 
{
 let $title := normalize-space($ead/ead:eadheader/ead:filedesc/ead:titlestmt/ead:titleproper)
 return
 <ead>
  <id>{ $ead/ead:eadheader/ead:eadid/text() }</id>
  <title>{ $title }</title>
 </ead>
};

declare function local:prev-link($start, $rpp, $max)
{
   "<" || $config:pulfa-root || rest:base-uri() || "/pulfa/collections?start=" || 
          max((($start - $rpp), 0)) || "&amp;rpp=" || $rpp ||  ">;rel=prev"
};


declare function local:next-link($start, $rpp, $max)
{
   "<" || $config:pulfa-root || rest:base-uri() || "/pulfa/collections?start=" || 
          min((($start + $rpp + 1), $max)) || "&amp;rpp=" || $rpp ||  ">;rel=next"
};

(:~
 : /pulfa
 :
 : The top level of the service.
 :)
declare
 %rest:GET
 %rest:path("/pulfa")
 %output:method("html5")
function api:hello() {
(
<rest:response><http:response status="200"/></rest:response>,
<html>
 <body>
  <p>Hello, world</p>
  </body>
</html>
)
};

(::::::::::: Repositories ::::::::::)
declare
 %rest:GET
 %rest:path("/pulfa/repositories")
 %output:method("json")
 %rest:produces("application/json")
 function api:repositories-as-json()
 as item()+
 {
  let $response := doc('/db/pulfa-data/vcards.rdf')//vc:VCard
  return
   (<rest:response>
      <http:response status="{ if (empty($response)) then 204 else 200 }">
       <http:header name="Content-Type" value="application/json"/>
      <http:header name="Access-Control-Allow-Origin" value="*"/>     
      </http:response>

   </rest:response>,
   <repositories>
    { for $r in $response return local:repo-component($r) }
    </repositories>)
 };

declare
 %rest:GET
 %rest:path("/pulfa/repositories/{$id}")
 %output:method("json")
 %rest:produces("application/json")
 function api:repository-as-json($id as xs:string)
 as item()+
 {
  let $response := doc('/db/pulfa-data/vcards.rdf')//vc:VCard[@rdf:about=$id]
  return
   (<rest:response>
      <http:response status="{ if (empty($response)) then 204 else 200 }">
       <http:header name="Content-Type" value="application/json"/>
       <http:header name="Access-Control-Allow-Origin" value="*"/>
     </http:response>
   </rest:response>,
   $response)
 };



(::::::::::: Collections ::::::::::)

declare 
 %rest:GET
 %rest:path("/pulfa/collections")
 %rest:query-param("start", "{$start}", 0)
 %rest:query-param("rpp", "{$rpp}", 10)
 %output:method("json")
 %rest:produces("application/json") 
function local:collections-as-json($start as xs:integer+, $rpp as xs:integer+)
as item()+
{
 let $collections := sort(collection('/db/pulfa-data')//ead:ead, (),
                          function($x)
                           { normalize-space($x/ead:eadheader/ead:filedesc/ead:titlestmt/ead:titleproper) })
  let $response := for $c in subsequence($collections, $start, $rpp) return local:ead-struct($c)
  let $max := count($collections)
  let $prev-index := max((($start - $rpp), 0))
  let $prevlink := "<" || $config:pulfa-root || rest:base-uri() || "/pulfa/collections?start=" || $prev-index || 
                    "&amp;rpp=" || $rpp ||  ">;rel=prev"
 return
  (<rest:response>
     <http:response status="{ if (empty($response)) then 204 else 200 }">
     <http:header name="Content-Type" value="application/json"/>
     <http:header name="Access-Control-Allow-Origin" value="*"/>
     <http:header name="Link" value="{local:prev-link($start, $rpp, $max)}, {local:next-link($start, $rpp, $max)}"/>
    </http:response>
  </rest:response>,
  $response)
};

declare
 %rest:GET
 %rest:path("/pulfa/collections/{$callno}")
  %output:method("json")
  %rest:produces("application/json")
function api:collections1-as-json($callno as xs:string)
as item()+
{
 let $response := <collection id="{$callno}"/>
 return
  (<rest:response>
     <http:response status="{ if (empty($response)) then 204 else 200 }">
      <http:header name="Content-Type" value="application/json"/>
      <http:header name="Access-Control-Allow-Origin" value="*"/>
    </http:response>
  </rest:response>,
  $response)
};


declare
 %rest:GET
 %rest:path("/pulfa/collections/{$callno}/{$componentid}")
  %output:method("json")
  %rest:produces("application/json")
function api:collections2-as-json($callno as xs:string, $componentid as xs:string)
as item()+
{
 let $response := <collection id="{$callno}"><component id="{$componentid}"/></collection>
 return
  (<rest:response>
     <http:response status="{ if (empty($response)) then 204 else 200 }">
      <http:header name="Content-Type" value="application/json"/>
      <http:header name="Access-Control-Allow-Origin" value="*"/>
    </http:response>
  </rest:response>,
  $response)
};