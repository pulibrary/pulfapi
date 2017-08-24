xquery version "3.1";

module namespace api="http://library.princeton.edu/apps/pulfa/api";

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace rest = "http://exquery.org/ns/restxq" ;

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http = "http://expath.org/ns/http-client"; 


declare
 %rest:GET
 %rest:path("/pulfa/api")
 %output:method("json")
 %rest:produces("application/json")
function api:ping()
{
    let $response := <h1>hello, world</h1>
    return
    (
    <rest:response>
        <http:response status="200">
            <http:header name="Access-Control-Allow-Origin" value="*"/>
        </http:response>
    </rest:response>,
        <p>Hello, World!</p>)
};