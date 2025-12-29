<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="es" xml:lang="es"><head>
<meta content="text/html; charset=ISO-8859-1" http-equiv="Content-Type" />
<!--
        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
              This file is generated from xml source: DO NOT EDIT
        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      -->
<title>core - Servidor HTTP Apache Versión 2.4</title>
<link href="../style/css/manual.css" rel="stylesheet" media="all" type="text/css" title="Main stylesheet" />
<link href="../style/css/manual-loose-100pc.css" rel="alternate stylesheet" media="all" type="text/css" title="No Sidebar - Default font size" />
<link href="../style/css/manual-print.css" rel="stylesheet" media="print" type="text/css" /><link rel="stylesheet" type="text/css" href="../style/css/prettify.css" />
<script src="../style/scripts/prettify.min.js" type="text/javascript">
</script>

<link href="../images/favicon.ico" rel="shortcut icon" /></head>
<body>
<div id="page-header">
<p class="menu"><a href="../mod/">Módulos</a> | <a href="../mod/directives.html">Directivas</a> | <a href="http://wiki.apache.org/httpd/FAQ">Preguntas Frecuentes</a> | <a href="../glossary.html">Glosario</a> | <a href="../sitemap.html">Mapa del sitio web</a></p>
<p class="apache">Versión 2.4 del Servidor HTTP Apache</p>
<img alt="" src="../images/feather.png" /></div>
<div class="up"><a href="./"><img title="&lt;-" alt="&lt;-" src="../images/left.gif" /></a></div>
<div id="path">
<a href="http://www.apache.org/">Apache</a> &gt; <a href="http://httpd.apache.org/">Servidor HTTP</a> &gt; <a href="http://httpd.apache.org/docs/">Documentación</a> &gt; <a href="../">Versión 2.4</a> &gt; <a href="./">Módulos</a></div>
<div id="page-content">
<div id="preamble"><h1>Funcionalidad Básica de Apache</h1>
<div class="toplang">
<p><span>Idiomas disponibles: </span><a href="../de/mod/core.html" hreflang="de" rel="alternate" title="Deutsch">&nbsp;de&nbsp;</a> |
<a href="../en/mod/core.html" hreflang="en" rel="alternate" title="English">&nbsp;en&nbsp;</a> |
<a href="../es/mod/core.html" title="Español">&nbsp;es&nbsp;</a> |
<a href="../fr/mod/core.html" hreflang="fr" rel="alternate" title="Français">&nbsp;fr&nbsp;</a> |
<a href="../ja/mod/core.html" hreflang="ja" rel="alternate" title="Japanese">&nbsp;ja&nbsp;</a> |
<a href="../tr/mod/core.html" hreflang="tr" rel="alternate" title="Türkçe">&nbsp;tr&nbsp;</a></p>
</div>
<div class="outofdate">Esta traducción podría estar
            obsoleta. Consulte la versión en inglés de la
            documentación para comprobar si se han producido cambios
            recientemente.</div>
<table class="module"><tr><th><a href="module-dict.html#Description">Descripción:</a></th><td>Funcionalides básicas del Servidor HTTP Apache que siempre están presentes.</td></tr>
<tr><th><a href="module-dict.html#Status">Estado:</a></th><td>Core</td></tr></table>
</div>
<div id="quickview"><a href="https://www.apache.org/foundation/contributing.html" class="badge"><img src="https://www.apache.org/images/SupportApache-small.png" alt="Support Apache!" /></a><h3 class="directives">Directivas</h3>
<ul id="toc">
<li><img alt="" src="../images/down.gif" /> <a href="#acceptfilter">AcceptFilter</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#acceptpathinfo">AcceptPathInfo</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#accessfilename">AccessFileName</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#adddefaultcharset">AddDefaultCharset</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#allowencodedslashes">AllowEncodedSlashes</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#allowoverride">AllowOverride</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#allowoverridelist">AllowOverrideList</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#cgimapextension">CGIMapExtension</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#cgipassauth">CGIPassAuth</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#cgivar">CGIVar</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#contentdigest">ContentDigest</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#defaultruntimedir">DefaultRuntimeDir</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#defaulttype">DefaultType</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#define">Define</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#directory">&lt;Directory&gt;</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#directorymatch">&lt;DirectoryMatch&gt;</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#documentroot">DocumentRoot</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#else">&lt;Else&gt;</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#elseif">&lt;ElseIf&gt;</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#enablemmap">EnableMMAP</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#enablesendfile">EnableSendfile</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#error">Error</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#errordocument">ErrorDocument</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#errorlog">ErrorLog</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#errorlogformat">ErrorLogFormat</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#extendedstatus">ExtendedStatus</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#fileetag">FileETag</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#files">&lt;Files&gt;</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#filesmatch">&lt;FilesMatch&gt;</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#forcetype">ForceType</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#gprofdir">GprofDir</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#hostnamelookups">HostnameLookups</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#httpprotocoloptions">HttpProtocolOptions</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#if">&lt;If&gt;</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#ifdefine">&lt;IfDefine&gt;</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#ifdirective">&lt;IfDirective&gt;</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#iffile">&lt;IfFile&gt;</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#ifmodule">&lt;IfModule&gt;</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#ifsection">&lt;IfSection&gt;</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#include">Include</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#includeoptional">IncludeOptional</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#keepalive">KeepAlive</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#keepalivetimeout">KeepAliveTimeout</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#limit">&lt;Limit&gt;</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#limitexcept">&lt;LimitExcept&gt;</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#limitinternalrecursion">LimitInternalRecursion</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#limitrequestbody">LimitRequestBody</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#limitrequestfields">LimitRequestFields</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#limitrequestfieldsize">LimitRequestFieldSize</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#limitrequestline">LimitRequestLine</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#limitxmlrequestbody">LimitXMLRequestBody</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#location">&lt;Location&gt;</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#locationmatch">&lt;LocationMatch&gt;</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#loglevel">LogLevel</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#maxkeepaliverequests">MaxKeepAliveRequests</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#maxrangeoverlaps">MaxRangeOverlaps</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#maxrangereversals">MaxRangeReversals</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#maxranges">MaxRanges</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#mergetrailers">MergeTrailers</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#mutex">Mutex</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#namevirtualhost">NameVirtualHost</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#options">Options</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#protocol">Protocol</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#protocols">Protocols</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#protocolshonororder">ProtocolsHonorOrder</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#qualifyredirecturl">QualifyRedirectURL</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#regexdefaultoptions">RegexDefaultOptions</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#registerhttpmethod">RegisterHttpMethod</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#rlimitcpu">RLimitCPU</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#rlimitmem">RLimitMEM</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#rlimitnproc">RLimitNPROC</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#scriptinterpretersource">ScriptInterpreterSource</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#seerequesttail">SeeRequestTail</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#serveradmin">ServerAdmin</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#serveralias">ServerAlias</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#servername">ServerName</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#serverpath">ServerPath</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#serverroot">ServerRoot</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#serversignature">ServerSignature</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#servertokens">ServerTokens</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#sethandler">SetHandler</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#setinputfilter">SetInputFilter</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#setoutputfilter">SetOutputFilter</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#timeout">TimeOut</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#traceenable">TraceEnable</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#undefine">UnDefine</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#usecanonicalname">UseCanonicalName</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#usecanonicalphysicalport">UseCanonicalPhysicalPort</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#virtualhost">&lt;VirtualHost&gt;</a></li>
</ul>
<h3>Lista de comprobación de errores corregidos</h3><ul class="seealso"><li><a href="https://www.apache.org/dist/httpd/CHANGES_2.4">httpd historial de cambios</a></li><li><a href="https://bz.apache.org/bugzilla/buglist.cgi?bug_status=__open__&amp;list_id=144532&amp;product=Apache%20httpd-2&amp;query_format=specific&amp;order=changeddate%20DESC%2Cpriority%2Cbug_severity&amp;component=core">Problemas Conocidos</a></li><li><a href="https://bz.apache.org/bugzilla/enter_bug.cgi?product=Apache%20httpd-2&amp;component=core">Reportar un error</a></li></ul><h3>Consulte también</h3>
<ul class="seealso">
<li><a href="#comments_section">Comentarios</a></li></ul></div>

<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="acceptfilter" id="acceptfilter">Directiva</a> <a name="AcceptFilter" id="AcceptFilter">AcceptFilter</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Configura mejoras para un Protocolo de Escucha de Sockets</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>AcceptFilter <var>protocol</var> <var>accept_filter</var></code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Disponible en Apache httpd 2.1.5 y posteriores.
En Windows desde Apache httpd 2.3.3 y posteriores.</td></tr>
</table>
    <p>Esta directiva hace posible mejoras específicas a nivel de sistema operativo
       y a través del tipo de Protocolo para un socket que escucha.
       La premisa básica es que el kernel no envíe un socket al servidor
       hasta que o bien los datos se hayan recibido o bien se haya almacenado
       en el buffer una Respuesta HTTP completa.  
       Actualmente sólo están soportados
       <a href="http://www.freebsd.org/cgi/man.cgi?query=accept_filter&amp;sektion=9">
       Accept Filters</a> sobre FreeBSD, <code>TCP_DEFER_ACCEPT</code> sobre Linux, 
       y AcceptEx() sobre Windows.</p>

    <p>El uso de <code>none</code> para un argumento desactiva cualquier filtro 
       aceptado para ese protocolo. Esto es útil para protocolos que requieren que un
       servidor envíe datos primeros, tales como <code>ftp:</code> o <code>nntp</code>:</p>
    <div class="example"><p><code>AcceptFilter nntp none</code></p></div>

    <p>Los nombres de protocolo por defecto son <code>https</code> para el puerto 443
       y <code>http</code> para todos los demás puertos. Para especificar que se está
       utilizando otro protocolo con un puerto escuchando, añade el argumento <var>protocol</var>
       a la directiva <code class="directive"><a href="../mod/mpm_common.html#listen">Listen</a></code>.</p>

    <p>Sobre FreeBDS los valores por defecto:</p>
    <div class="example"><p><code>
        AcceptFilter http httpready <br />
        AcceptFilter https dataready
    </code></p></div>
    
    <p>El filtro <code>httpready</code> almacena en el buffer peticiones HTTP completas
       a nivel de kernel.  Una vez que la petición es recibida, el kernel la envía al servidor. 
       Consulta la página man de
       <a href="http://www.freebsd.org/cgi/man.cgi?query=accf_http&amp;sektion=9">
       accf_http(9)</a> para más detalles.  Puesto que las peticiones HTTPS
       están encriptadas, sólo se utiliza el filtro
       <a href="http://www.freebsd.org/cgi/man.cgi?query=accf_data&amp;sektion=9">accf_data(9)</a>.</p>

    <p>Sobre Linux los valores por defecto son:</p>
    <div class="example"><p><code>
        AcceptFilter http data <br />
        AcceptFilter https data
    </code></p></div>

    <p>En Linux, <code>TCP_DEFER_ACCEPT</code> no soporta el buffering en peticiones http.
       Cualquier valor además de <code>none</code> habilitará 
       <code>TCP_DEFER_ACCEPT</code> en ese socket. Para más detalles 
       ver la página man de Linux 
       <a href="http://homepages.cwi.nl/~aeb/linux/man2html/man7/tcp.7.html">
       tcp(7)</a>.</p>

    <p>Sobre Windows los valores por defecto son:</p>
    <div class="example"><p><code>
        AcceptFilter http data <br />
        AcceptFilter https data
    </code></p></div>

    <p>Sobre Windows mpm_winnt interpreta el argumento AcceptFilter para conmutar la API
       AcceptEx(), y no soporta el buffering sobre el protocolo http.  Hay dos valores
       que utilizan la API Windows AcceptEx() y que recuperan sockets de red
       entre conexciones.  <code>data</code> espera hasta que los datos han sido
       transmitidos como se comentaba anteriormente, y el buffer inicial de datos y las
       direcciones de red son recuperadas a partir de una única llamada AcceptEx().
       <code>connect</code> utiliza la API AcceptEx() API, y recupera también
       las direcciones de red, pero a diferencia de <code>none</code> 
       la opción <code>connect</code> no espera a la transmisión inicial de los datos.</p>

    <p>Sobre Windows, <code>none</code> prefiere accept() antes que AcceptEx()
       y no recuperará sockets entre las conexiones.  Lo que es útil para los adaptadores de
       red con un soporte precario de drivers, así como para algunos proveedores de red
       tales como drivers vpn, o filtros de spam, de virus o de spyware.</p>  


<h3>Consulte también</h3>
<ul>
<li><code class="directive">Protocol</code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="acceptpathinfo" id="acceptpathinfo">Directiva</a> <a name="AcceptPathInfo" id="AcceptPathInfo">AcceptPathInfo</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Los recursos aceptan información sobre su ruta</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>AcceptPathInfo On|Off|Default</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>AcceptPathInfo Default</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>FileInfo</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Disponible en Apache httpd 2.0.30 y posteriores</td></tr>
</table>

    <p>Esta directiva controla si las peticiones que contienen información sobre la ruta
    que sigue un fichero que existe (o un fichero que no existe pero en un directorio que
    sí existe) serán aceptadas o denegadas.  La información de ruta puede estar disponible
    para los scripts en la variable de entorno <code>PATH_INFO</code>.</p>

    <p>Por ejemplo, asumamos que la ubicación <code>/test/</code> apunta a
    un directorio que contiene únicamente el fichero
    <code>here.html</code>.  Entonces, las peticiones tanto para
    <code>/test/here.html/more</code> como para
    <code>/test/nothere.html/more</code> recogen
    <code>/more</code> como <code>PATH_INFO</code>.</p>

    <p>Los tres posibles argumentos para la directiva
    <code class="directive">AcceptPathInfo</code> son los siguientes:</p>
    <dl>
    <dt><code>Off</code></dt><dd>Una petición sólo será aceptada si
    se corresponde con una ruta literal que existe.  Por lo tanto, una petición
    con una información de ruta después del nombre de fichero tal como
    <code>/test/here.html/more</code> en el ejemplo anterior devolverá
    un error 404 NOT FOUND.</dd>

    <dt><code>On</code></dt><dd>Una petición será aceptada si una
    ruta principal de acceso se corresponde con un fichero que existe. El ejemplo
    anterior <code>/test/here.html/more</code> será aceptado si
    <code>/test/here.html</code> corresponde a un fichero válido.</dd>

    <dt><code>Default</code></dt><dd>La gestión de las peticiones
    con información de ruta está determinada por el <a href="../handler.html">controlador</a> responsable de la petición.
    El controlador principal para para ficheros normales rechaza por defecto
    peticiones <code>PATH_INFO</code>. Los controladores que sirven scripts, tales como <a href="mod_cgi.html">cgi-script</a> e <a href="mod_isapi.html">isapi-handler</a>, normalmente aceptan
    <code>PATH_INFO</code> por defecto.</dd>
    </dl>

    <p>El objetivo principal de la directiva <code>AcceptPathInfo</code>
    es permitirte sobreescribir la opción del controlador
    de aceptar or rechazar <code>PATH_INFO</code>. Este tipo de sobreescritura se necesita,
    por ejemplo, cuando utilizas un <a href="../filter.html">filtro</a>, tal como
    <a href="mod_include.html">INCLUDES</a>, para generar contenido
    basado en <code>PATH_INFO</code>. El controlador principal normalmente rechazaría
    la petición, de modo que puedes utilizar la siguiente configuración para habilitarla
    como script:</p>

    <div class="example"><p><code>
      &lt;Files "mypaths.shtml"&gt;<br />
      <span class="indent">
        Options +Includes<br />
        SetOutputFilter INCLUDES<br />
        AcceptPathInfo On<br />
      </span>
      &lt;/Files&gt;
    </code></p></div>


</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="accessfilename" id="accessfilename">Directiva</a> <a name="AccessFileName" id="AccessFileName">AccessFileName</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Nombre del fichero distribuido de configuración</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>AccessFileName <var>filename</var> [<var>filename</var>] ...</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>AccessFileName .htaccess</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>Mientras que procesa una petición el servidor busca
    el primer fichero de configuración existente dentro de un listado de nombres en
    cada directorio de la ruta del documento, si los ficheros distribuidos
    de configuración están <a href="#allowoverride">habilitados para ese
    directorio</a>. Por ejemplo:</p>

    <div class="example"><p><code>
      AccessFileName .acl
    </code></p></div>

    <p>antes de servir el documento
    <code>/usr/local/web/index.html</code>, el servidor leerá
    <code>/.acl</code>, <code>/usr/.acl</code>,
    <code>/usr/local/.acl</code> and <code>/usr/local/web/.acl</code>
    para las directivas, salvo que estén deshabilitadas with</p>

    <div class="example"><p><code>
      &lt;Directory /&gt;<br />
      <span class="indent">
        AllowOverride None<br />
      </span>
      &lt;/Directory&gt;
    </code></p></div>

<h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#allowoverride">AllowOverride</a></code></li>
<li><a href="../configuring.html">Configuration Files</a></li>
<li><a href="../howto/htaccess.html">.htaccess Files</a></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="adddefaultcharset" id="adddefaultcharset">Directiva</a> <a name="AddDefaultCharset" id="AddDefaultCharset">AddDefaultCharset</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Default charset parameter to be added when a response
content-type is <code>text/plain</code> or <code>text/html</code></td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>AddDefaultCharset On|Off|<var>charset</var></code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>AddDefaultCharset Off</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>FileInfo</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>This directive specifies a default value for the media type
    charset parameter (the name of a character encoding) to be added
    to a response if and only if the response's content-type is either
    <code>text/plain</code> or <code>text/html</code>.  This should override
    any charset specified in the body of the response via a <code>META</code>
    element, though the exact behavior is often dependent on the user's client
    configuration. A setting of <code>AddDefaultCharset Off</code>
    disables this functionality. <code>AddDefaultCharset On</code> enables
    a default charset of <code>iso-8859-1</code>. Any other value is assumed
    to be the <var>charset</var> to be used, which should be one of the
    <a href="http://www.iana.org/assignments/character-sets">IANA registered
    charset values</a> for use in Internet media types (MIME types).
    For example:</p>

    <div class="example"><p><code>
      AddDefaultCharset utf-8
    </code></p></div>

    <p><code class="directive">AddDefaultCharset</code> should only be used when all
    of the text resources to which it applies are known to be in that
    character encoding and it is too inconvenient to label their charset
    individually. One such example is to add the charset parameter
    to resources containing generated content, such as legacy CGI
    scripts, that might be vulnerable to cross-site scripting attacks
    due to user-provided data being included in the output.  Note, however,
    that a better solution is to just fix (or delete) those scripts, since
    setting a default charset does not protect users that have enabled
    the "auto-detect character encoding" feature on their browser.</p>

<h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="../mod/mod_mime.html#addcharset">AddCharset</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="allowencodedslashes" id="allowencodedslashes">Directiva</a> <a name="AllowEncodedSlashes" id="AllowEncodedSlashes">AllowEncodedSlashes</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Determines whether encoded path separators in URLs are allowed to
be passed through</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>AllowEncodedSlashes On|Off</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>AllowEncodedSlashes Off</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in Apache httpd 2.0.46 and later</td></tr>
</table>
    <p>The <code class="directive">AllowEncodedSlashes</code> directive allows URLs
    which contain encoded path separators (<code>%2F</code> for <code>/</code>
    and additionally <code>%5C</code> for <code>\</code> on according systems)
    to be used. Normally such URLs are refused with a 404 (Not found) error.</p>

    <p>Turning <code class="directive">AllowEncodedSlashes</code> <code>On</code> is
    mostly useful when used in conjunction with <code>PATH_INFO</code>.</p>

    <div class="note"><h3>Note</h3>
      <p>Allowing encoded slashes does <em>not</em> imply <em>decoding</em>.
      Occurrences of <code>%2F</code> or <code>%5C</code> (<em>only</em> on
      according systems) will be left as such in the otherwise decoded URL
      string.</p>
    </div>

<h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#acceptpathinfo">AcceptPathInfo</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="allowoverride" id="allowoverride">Directiva</a> <a name="AllowOverride" id="AllowOverride">AllowOverride</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Types of directives that are allowed in
<code>.htaccess</code> files</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>AllowOverride All|None|<var>directive-type</var>
[<var>directive-type</var>] ...</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>AllowOverride None (2.3.9 and later), AllowOverride All (2.3.8 and earlier)</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>directory</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>When the server finds an <code>.htaccess</code> file (as
    specified by <code class="directive"><a href="#accessfilename">AccessFileName</a></code>)
    it needs to know which directives declared in that file can override
    earlier configuration directives.</p>

    <div class="note"><h3>Only available in &lt;Directory&gt; sections</h3>
    <code class="directive">AllowOverride</code> is valid only in
    <code class="directive"><a href="#directory">&lt;Directory&gt;</a></code>
    sections specified without regular expressions, not in <code class="directive"><a href="#location">&lt;Location&gt;</a></code>, <code class="directive"><a href="#directorymatch">&lt;DirectoryMatch&gt;</a></code> or
    <code class="directive"><a href="#files">&lt;Files&gt;</a></code> sections.
    </div>

    <p>When this directive is set to <code>None</code>, then
    <a href="#accessfilename">.htaccess</a> files are completely ignored.
    In this case, the server will not even attempt to read
    <code>.htaccess</code> files in the filesystem.</p>

    <p>When this directive is set to <code>All</code>, then any
    directive which has the .htaccess <a href="directive-dict.html#Context">Context</a> is allowed in
    <code>.htaccess</code> files.</p>

    <p>The <var>directive-type</var> can be one of the following
    groupings of directives.</p>

    <dl>
      <dt>AuthConfig</dt>

      <dd>

      Allow use of the authorization directives (<code class="directive"><a href="../mod/mod_authn_dbm.html#authdbmgroupfile">AuthDBMGroupFile</a></code>,
      <code class="directive"><a href="../mod/mod_authn_dbm.html#authdbmuserfile">AuthDBMUserFile</a></code>,
      <code class="directive"><a href="../mod/mod_authz_groupfile.html#authgroupfile">AuthGroupFile</a></code>,
      <code class="directive"><a href="../mod/mod_authn_core.html#authname">AuthName</a></code>,
      <code class="directive"><a href="../mod/mod_authn_core.html#authtype">AuthType</a></code>, <code class="directive"><a href="../mod/mod_authn_file.html#authuserfile">AuthUserFile</a></code>, <code class="directive"><a href="../mod/mod_authz_core.html#require">Require</a></code>, <em>etc.</em>).</dd>

      <dt>FileInfo</dt>

      <dd>
      Allow use of the directives controlling document types
     (<code class="directive"><a href="#errordocument">ErrorDocument</a></code>,
      <code class="directive"><a href="#forcetype">ForceType</a></code>,
      <code class="directive"><a href="../mod/mod_negotiation.html#languagepriority">LanguagePriority</a></code>,
      <code class="directive"><a href="#sethandler">SetHandler</a></code>,
      <code class="directive"><a href="#setinputfilter">SetInputFilter</a></code>,
      <code class="directive"><a href="#setoutputfilter">SetOutputFilter</a></code>, and
      <code class="module"><a href="../mod/mod_mime.html">mod_mime</a></code> Add* and Remove* directives),
      document meta data (<code class="directive"><a href="../mod/mod_headers.html#header">Header</a></code>, <code class="directive"><a href="../mod/mod_headers.html#requestheader">RequestHeader</a></code>, <code class="directive"><a href="../mod/mod_setenvif.html#setenvif">SetEnvIf</a></code>, <code class="directive"><a href="../mod/mod_setenvif.html#setenvifnocase">SetEnvIfNoCase</a></code>, <code class="directive"><a href="../mod/mod_setenvif.html#browsermatch">BrowserMatch</a></code>, <code class="directive"><a href="../mod/mod_usertrack.html#cookieexpires">CookieExpires</a></code>, <code class="directive"><a href="../mod/mod_usertrack.html#cookiedomain">CookieDomain</a></code>, <code class="directive"><a href="../mod/mod_usertrack.html#cookiestyle">CookieStyle</a></code>, <code class="directive"><a href="../mod/mod_usertrack.html#cookietracking">CookieTracking</a></code>, <code class="directive"><a href="../mod/mod_usertrack.html#cookiename">CookieName</a></code>),
      <code class="module"><a href="../mod/mod_rewrite.html">mod_rewrite</a></code> directives <code class="directive"><a href="../mod/mod_rewrite.html#rewriteengine">RewriteEngine</a></code>, <code class="directive"><a href="../mod/mod_rewrite.html#rewriteoptions">RewriteOptions</a></code>, <code class="directive"><a href="../mod/mod_rewrite.html#rewritebase">RewriteBase</a></code>, <code class="directive"><a href="../mod/mod_rewrite.html#rewritecond">RewriteCond</a></code>, <code class="directive"><a href="../mod/mod_rewrite.html#rewriterule">RewriteRule</a></code>) and
      <code class="directive"><a href="../mod/mod_actions.html#action">Action</a></code> from
      <code class="module"><a href="../mod/mod_actions.html">mod_actions</a></code>.
      </dd>

      <dt>Indexes</dt>

      <dd>
      Allow use of the directives controlling directory indexing
      (<code class="directive"><a href="../mod/mod_autoindex.html#adddescription">AddDescription</a></code>,
      <code class="directive"><a href="../mod/mod_autoindex.html#addicon">AddIcon</a></code>, <code class="directive"><a href="../mod/mod_autoindex.html#addiconbyencoding">AddIconByEncoding</a></code>,
      <code class="directive"><a href="../mod/mod_autoindex.html#addiconbytype">AddIconByType</a></code>,
      <code class="directive"><a href="../mod/mod_autoindex.html#defaulticon">DefaultIcon</a></code>, <code class="directive"><a href="../mod/mod_dir.html#directoryindex">DirectoryIndex</a></code>, <code class="directive"><a href="../mod/mod_autoindex.html#fancyindexing">FancyIndexing</a></code>, <code class="directive"><a href="../mod/mod_autoindex.html#headername">HeaderName</a></code>, <code class="directive"><a href="../mod/mod_autoindex.html#indexignore">IndexIgnore</a></code>, <code class="directive"><a href="../mod/mod_autoindex.html#indexoptions">IndexOptions</a></code>, <code class="directive"><a href="../mod/mod_autoindex.html#readmename">ReadmeName</a></code>,
      <em>etc.</em>).</dd>

      <dt>Limit</dt>

      <dd>
      Allow use of the directives controlling host access (<code class="directive"><a href="../mod/mod_authz_host.html#allow">Allow</a></code>, <code class="directive"><a href="../mod/mod_authz_host.html#deny">Deny</a></code> and <code class="directive"><a href="../mod/mod_authz_host.html#order">Order</a></code>).</dd>

      <dt>Options[=<var>Option</var>,...]</dt>

      <dd>
      Allow use of the directives controlling specific directory
      features (<code class="directive"><a href="#options">Options</a></code> and
      <code class="directive"><a href="../mod/mod_include.html#xbithack">XBitHack</a></code>).
      An equal sign may be given followed by a comma (but no spaces)
      separated lists of options that may be set using the <code class="directive"><a href="#options">Options</a></code> command.</dd>
    </dl>

    <p>Example:</p>

    <div class="example"><p><code>
      AllowOverride AuthConfig Indexes
    </code></p></div>

    <p>In the example above all directives that are neither in the group
    <code>AuthConfig</code> nor <code>Indexes</code> cause an internal
    server error.</p>

    <div class="note"><p>For security and performance reasons, do not set
    <code>AllowOverride</code> to anything other than <code>None</code> 
    in your <code>&lt;Directory /&gt;</code> block. Instead, find (or
    create) the <code>&lt;Directory&gt;</code> block that refers to the
    directory where you're actually planning to place a
    <code>.htaccess</code> file.</p>
    </div>

<h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#accessfilename">AccessFileName</a></code></li>
<li><a href="../configuring.html">Configuration Files</a></li>
<li><a href="../howto/htaccess.html">.htaccess Files</a></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="allowoverridelist" id="allowoverridelist">Directiva</a> <a name="AllowOverrideList" id="AllowOverrideList">AllowOverrideList</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Individual directives that are allowed in
<code>.htaccess</code> files</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>AllowOverrideList None|<var>directive</var>
[<var>directive-type</var>] ...</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>AllowOverrideList None</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>directory</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p><h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#accessfilename">AccessFileName</a></code></li>
<li><code class="directive"><a href="#allowoverride">AllowOverride</a></code></li>
<li><a href="../configuring.html">Configuration Files</a></li>
<li><a href="../howto/htaccess.html">.htaccess Files</a></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="cgimapextension" id="cgimapextension">Directiva</a> <a name="CGIMapExtension" id="CGIMapExtension">CGIMapExtension</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Technique for locating the interpreter for CGI
scripts</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>CGIMapExtension <var>cgi-path</var> <var>.extension</var></code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>FileInfo</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>NetWare only</td></tr>
</table>
    <p>This directive is used to control how Apache httpd finds the
    interpreter used to run CGI scripts. For example, setting
    <code>CGIMapExtension sys:\foo.nlm .foo</code> will
    cause all CGI script files with a <code>.foo</code> extension to
    be passed to the FOO interpreter.</p>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="cgipassauth" id="cgipassauth">Directiva</a> <a name="CGIPassAuth" id="CGIPassAuth">CGIPassAuth</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Enables passing HTTP authorization headers to scripts as CGI
variables</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>CGIPassAuth On|Off</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>CGIPassAuth Off</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>AuthConfig</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in Apache HTTP Server 2.4.13 and later</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p></div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="cgivar" id="cgivar">Directiva</a> <a name="CGIVar" id="CGIVar">CGIVar</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Controls how some CGI variables are set</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>CGIVar <var>variable</var> <var>rule</var></code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>FileInfo</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in Apache HTTP Server 2.4.21 and later</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p></div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="contentdigest" id="contentdigest">Directiva</a> <a name="ContentDigest" id="ContentDigest">ContentDigest</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Enables the generation of <code>Content-MD5</code> HTTP Response
headers</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>ContentDigest On|Off</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>ContentDigest Off</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>Options</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>This directive enables the generation of
    <code>Content-MD5</code> headers as defined in RFC1864
    respectively RFC2616.</p>

    <p>MD5 is an algorithm for computing a "message digest"
    (sometimes called "fingerprint") of arbitrary-length data, with
    a high degree of confidence that any alterations in the data
    will be reflected in alterations in the message digest.</p>

    <p>The <code>Content-MD5</code> header provides an end-to-end
    message integrity check (MIC) of the entity-body. A proxy or
    client may check this header for detecting accidental
    modification of the entity-body in transit. Example header:</p>

    <div class="example"><p><code>
      Content-MD5: AuLb7Dp1rqtRtxz2m9kRpA==
    </code></p></div>

    <p>Note that this can cause performance problems on your server
    since the message digest is computed on every request (the
    values are not cached).</p>

    <p><code>Content-MD5</code> is only sent for documents served
    by the <code class="module"><a href="../mod/core.html">core</a></code>, and not by any module. For example,
    SSI documents, output from CGI scripts, and byte range responses
    do not have this header.</p>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="defaultruntimedir" id="defaultruntimedir">Directiva</a> <a name="DefaultRuntimeDir" id="DefaultRuntimeDir">DefaultRuntimeDir</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Base directory for the server run-time files</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>DefaultRuntimeDir <var>directory-path</var></code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>DefaultRuntimeDir DEFAULT_REL_RUNTIMEDIR (logs/)</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in Apache 2.4.2 and later</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p><h3>Consulte también</h3>
<ul>
<li><a href="../misc/security_tips.html#serverroot">the
    security tips</a> for information on how to properly set
    permissions on the <code class="directive">ServerRoot</code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="defaulttype" id="defaulttype">Directiva</a> <a name="DefaultType" id="DefaultType">DefaultType</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>This directive has no effect other than to emit warnings
if the value is not <code>none</code>. In prior versions, DefaultType
would specify a default media type to assign to response content for
which no other media type configuration could be found.
</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>DefaultType <var>media-type|none</var></code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>DefaultType none</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>FileInfo</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>The argument <code>none</code> is available in Apache httpd 2.2.7 and later.  All other choices are DISABLED for 2.3.x and later.</td></tr>
</table>
    <p>This directive has been disabled.  For backwards compatibility
    of configuration files, it may be specified with the value
    <code>none</code>, meaning no default media type. For example:</p>

    <div class="example"><p><code>
      DefaultType None
    </code></p></div>

    <p><code>DefaultType None</code> is only available in
    httpd-2.2.7 and later.</p>

    <p>Use the mime.types configuration file and the
    <code class="directive"><a href="../mod/mod_mime.html#addtype">AddType</a></code> to configure media
    type assignments via file extensions, or the
    <code class="directive"><a href="#forcetype">ForceType</a></code> directive to configure
    the media type for specific resources. Otherwise, the server will
    send the response without a Content-Type header field and the
    recipient may attempt to guess the media type.</p>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="define" id="define">Directiva</a> <a name="Define" id="Define">Define</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Define the existence of a variable</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>Define <var>parameter-name</var></code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>Equivalent to passing the <code>-D</code> argument to <code class="program"><a href="../programs/httpd.html">httpd</a></code>.</p>
    <p>This directive can be used to toggle the use of <code class="directive"><a href="#ifdefine">&lt;IfDefine&gt;</a></code> sections without needing to alter
    <code>-D</code> arguments in any startup scripts.</p>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="directory" id="directory">Directiva</a> <a name="Directory" id="Directory">&lt;Directory&gt;</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Enclose a group of directives that apply only to the
named file-system directory, sub-directories, and their contents.</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>&lt;Directory <var>directory-path</var>&gt;
... &lt;/Directory&gt;</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p><code class="directive">&lt;Directory&gt;</code> and
    <code>&lt;/Directory&gt;</code> are used to enclose a group of
    directives that will apply only to the named directory,
    sub-directories of that directory, and the files within the respective 
    directories.  Any directive that is allowed
    in a directory context may be used. <var>Directory-path</var> is
    either the full path to a directory, or a wild-card string using
    Unix shell-style matching. In a wild-card string, <code>?</code> matches
    any single character, and <code>*</code> matches any sequences of
    characters. You may also use <code>[]</code> character ranges. None
    of the wildcards match a `/' character, so <code>&lt;Directory
    /*/public_html&gt;</code> will not match
    <code>/home/user/public_html</code>, but <code>&lt;Directory
    /home/*/public_html&gt;</code> will match. Example:</p>

    <div class="example"><p><code>
      &lt;Directory /usr/local/httpd/htdocs&gt;<br />
      <span class="indent">
        Options Indexes FollowSymLinks<br />
      </span>
      &lt;/Directory&gt;
    </code></p></div>

    <div class="note">
      <p>Be careful with the <var>directory-path</var> arguments:
      They have to literally match the filesystem path which Apache httpd uses
      to access the files. Directives applied to a particular
      <code>&lt;Directory&gt;</code> will not apply to files accessed from
      that same directory via a different path, such as via different symbolic
      links.</p>
    </div>

    <p><a class="glossarylink" href="../glossary.html#regex" title="ver glosario">Regular
    expressions</a> can also be used, with the addition of the
    <code>~</code> character. For example:</p>

    <div class="example"><p><code>
      &lt;Directory ~ "^/www/.*/[0-9]{3}"&gt;
    </code></p></div>

    <p>would match directories in <code>/www/</code> that consisted of
    three numbers.</p>

    <p>If multiple (non-regular expression) <code class="directive">&lt;Directory&gt;</code> sections
    match the directory (or one of its parents) containing a document,
    then the directives are applied in the order of shortest match
    first, interspersed with the directives from the <a href="#accessfilename">.htaccess</a> files. For example,
    with</p>

    <div class="example"><p><code>
      &lt;Directory /&gt;<br />
      <span class="indent">
        AllowOverride None<br />
      </span>
      &lt;/Directory&gt;<br />
      <br />
      &lt;Directory /home/&gt;<br />
      <span class="indent">
        AllowOverride FileInfo<br />
      </span>
      &lt;/Directory&gt;
    </code></p></div>

    <p>for access to the document <code>/home/web/dir/doc.html</code>
    the steps are:</p>

    <ul>
      <li>Apply directive <code>AllowOverride None</code>
      (disabling <code>.htaccess</code> files).</li>

      <li>Apply directive <code>AllowOverride FileInfo</code> (for
      directory <code>/home</code>).</li>

      <li>Apply any <code>FileInfo</code> directives in
      <code>/home/.htaccess</code>, <code>/home/web/.htaccess</code> and
      <code>/home/web/dir/.htaccess</code> in that order.</li>
    </ul>

    <p>Regular expressions are not considered until after all of the
    normal sections have been applied. Then all of the regular
    expressions are tested in the order they appeared in the
    configuration file. For example, with</p>

    <div class="example"><p><code>
      &lt;Directory ~ abc$&gt;<br />
      <span class="indent">
        # ... directives here ...<br />
      </span>
      &lt;/Directory&gt;
    </code></p></div>

    <p>the regular expression section won't be considered until after
    all normal <code class="directive">&lt;Directory&gt;</code>s and
    <code>.htaccess</code> files have been applied. Then the regular
    expression will match on <code>/home/abc/public_html/abc</code> and
    the corresponding <code class="directive">&lt;Directory&gt;</code> will
    be applied.</p>

   <p><strong>Note that the default access for
    <code>&lt;Directory /&gt;</code> is <code>Allow from All</code>.
    This means that Apache httpd will serve any file mapped from an URL. It is
    recommended that you change this with a block such
    as</strong></p>

    <div class="example"><p><code>
      &lt;Directory /&gt;<br />
      <span class="indent">
        Order Deny,Allow<br />
        Deny from All<br />
      </span>
      &lt;/Directory&gt;
    </code></p></div>

    <p><strong>and then override this for directories you
    <em>want</em> accessible. See the <a href="../misc/security_tips.html">Security Tips</a> page for more
    details.</strong></p>

    <p>The directory sections occur in the <code>httpd.conf</code> file.
    <code class="directive">&lt;Directory&gt;</code> directives
    cannot nest, and cannot appear in a <code class="directive"><a href="#limit">&lt;Limit&gt;</a></code> or <code class="directive"><a href="#limitexcept">&lt;LimitExcept&gt;</a></code> section.</p>

<h3>Consulte también</h3>
<ul>
<li><a href="../sections.html">How &lt;Directory&gt;,
    &lt;Location&gt; and &lt;Files&gt; sections work</a> for an
    explanation of how these different sections are combined when a
    request is received</li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="directorymatch" id="directorymatch">Directiva</a> <a name="DirectoryMatch" id="DirectoryMatch">&lt;DirectoryMatch&gt;</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Enclose directives that apply to
the contents of file-system directories matching a regular expression.</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>&lt;DirectoryMatch <var>regex</var>&gt;
... &lt;/DirectoryMatch&gt;</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p><code class="directive">&lt;DirectoryMatch&gt;</code> and
    <code>&lt;/DirectoryMatch&gt;</code> are used to enclose a group
    of directives which will apply only to the named directory (and the files within), 
    the same as <code class="directive"><a href="#directory">&lt;Directory&gt;</a></code>. 
    However, it takes as an argument a 
    <a class="glossarylink" href="../glossary.html#regex" title="ver glosario">regular expression</a>.  For example:</p>

    <div class="example"><p><code>
      &lt;DirectoryMatch "^/www/(.+/)?[0-9]{3}"&gt;
    </code></p></div>

    <p>would match directories in <code>/www/</code> that consisted of three
    numbers.</p>

   <div class="note"><h3>Compatability</h3>
      Prior to 2.3.9, this directive implicitly applied to sub-directories
      (like <code class="directive"><a href="#directory">&lt;Directory&gt;</a></code>) and
      could not match the end of line symbol ($).  In 2.3.9 and later,
      only directories that match the expression are affected by the enclosed
      directives.
    </div>

    <div class="note"><h3>Trailing Slash</h3>
      This directive applies to requests for directories that may or may 
      not end in a trailing slash, so expressions that are anchored to the 
      end of line ($) must be written with care.
    </div>

<h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#directory">&lt;Directory&gt;</a></code> for
a description of how regular expressions are mixed in with normal
<code class="directive">&lt;Directory&gt;</code>s</li>
<li><a href="../sections.html">How &lt;Directory&gt;, &lt;Location&gt; and
&lt;Files&gt; sections work</a> for an explanation of how these different
sections are combined when a request is received</li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="documentroot" id="documentroot">Directiva</a> <a name="DocumentRoot" id="DocumentRoot">DocumentRoot</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Directory that forms the main document tree visible
from the web</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>DocumentRoot <var>directory-path</var></code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>DocumentRoot /usr/local/apache/htdocs</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>This directive sets the directory from which <code class="program"><a href="../programs/httpd.html">httpd</a></code>
    will serve files. Unless matched by a directive like <code class="directive"><a href="../mod/mod_alias.html#alias">Alias</a></code>, the server appends the
    path from the requested URL to the document root to make the
    path to the document. Example:</p>

    <div class="example"><p><code>
      DocumentRoot /usr/web
    </code></p></div>

    <p>then an access to
    <code>http://www.my.host.com/index.html</code> refers to
    <code>/usr/web/index.html</code>. If the <var>directory-path</var> is 
    not absolute then it is assumed to be relative to the <code class="directive"><a href="#serverroot">ServerRoot</a></code>.</p>

    <p>The <code class="directive">DocumentRoot</code> should be specified without
    a trailing slash.</p>

<h3>Consulte también</h3>
<ul>
<li><a href="../urlmapping.html#documentroot">Mapping URLs to Filesystem
Locations</a></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="else" id="else">Directiva</a> <a name="Else" id="Else">&lt;Else&gt;</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Contains directives that apply only if the condition of a
previous <code class="directive"><a href="#if">&lt;If&gt;</a></code> or
<code class="directive"><a href="#elseif">&lt;ElseIf&gt;</a></code> section is not
satisfied by a request at runtime</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>&lt;Else&gt; ... &lt;/Else&gt;</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>All</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Nested conditions are evaluated in 2.4.26 and later</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p><h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#if">&lt;If&gt;</a></code></li>
<li><code class="directive"><a href="#elseif">&lt;ElseIf&gt;</a></code></li>
<li><a href="../sections.html">How &lt;Directory&gt;, &lt;Location&gt;,
    &lt;Files&gt; sections work</a> for an explanation of how these
    different sections are combined when a request is received.
    <code class="directive">&lt;If&gt;</code>,
    <code class="directive">&lt;ElseIf&gt;</code>, and
    <code class="directive">&lt;Else&gt;</code> are applied last.</li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="elseif" id="elseif">Directiva</a> <a name="ElseIf" id="ElseIf">&lt;ElseIf&gt;</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Contains directives that apply only if a condition is satisfied
by a request at runtime while the condition of a previous
<code class="directive"><a href="#if">&lt;If&gt;</a></code> or
<code class="directive">&lt;ElseIf&gt;</code> section is not
satisfied</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>&lt;ElseIf <var>expression</var>&gt; ... &lt;/ElseIf&gt;</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>All</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Nested conditions are evaluated in 2.4.26 and later</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p><h3>Consulte también</h3>
<ul>
<li><a href="../expr.html">Expressions in Apache HTTP Server</a>,
for a complete reference and more examples.</li>
<li><code class="directive"><a href="#if">&lt;If&gt;</a></code></li>
<li><code class="directive"><a href="#else">&lt;Else&gt;</a></code></li>
<li><a href="../sections.html">How &lt;Directory&gt;, &lt;Location&gt;,
    &lt;Files&gt; sections work</a> for an explanation of how these
    different sections are combined when a request is received.
    <code class="directive">&lt;If&gt;</code>,
    <code class="directive">&lt;ElseIf&gt;</code>, and
    <code class="directive">&lt;Else&gt;</code> are applied last.</li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="enablemmap" id="enablemmap">Directiva</a> <a name="EnableMMAP" id="EnableMMAP">EnableMMAP</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Use memory-mapping to read files during delivery</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>EnableMMAP On|Off</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>EnableMMAP On</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>FileInfo</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>This directive controls whether the <code class="program"><a href="../programs/httpd.html">httpd</a></code> may use
    memory-mapping if it needs to read the contents of a file during
    delivery.  By default, when the handling of a request requires
    access to the data within a file -- for example, when delivering a
    server-parsed file using <code class="module"><a href="../mod/mod_include.html">mod_include</a></code> -- Apache httpd
    memory-maps the file if the OS supports it.</p>

    <p>This memory-mapping sometimes yields a performance improvement.
    But in some environments, it is better to disable the memory-mapping
    to prevent operational problems:</p>

    <ul>
    <li>On some multiprocessor systems, memory-mapping can reduce the
    performance of the <code class="program"><a href="../programs/httpd.html">httpd</a></code>.</li>
    <li>Deleting or truncating a file while <code class="program"><a href="../programs/httpd.html">httpd</a></code>
      has it memory-mapped can cause <code class="program"><a href="../programs/httpd.html">httpd</a></code> to
      crash with a segmentation fault.
    </li>
    </ul>

    <p>For server configurations that are vulnerable to these problems,
    you should disable memory-mapping of delivered files by specifying:</p>

    <div class="example"><p><code>
      EnableMMAP Off
    </code></p></div>

    <p>For NFS mounted files, this feature may be disabled explicitly for
    the offending files by specifying:</p>

    <div class="example"><p><code>
      &lt;Directory "/path-to-nfs-files"&gt;
      <span class="indent">
        EnableMMAP Off
      </span>
      &lt;/Directory&gt;
    </code></p></div>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="enablesendfile" id="enablesendfile">Directiva</a> <a name="EnableSendfile" id="EnableSendfile">EnableSendfile</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Use the kernel sendfile support to deliver files to the client</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>EnableSendfile On|Off</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>EnableSendfile Off</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>FileInfo</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in version 2.0.44 and later. Default changed to Off in
version 2.3.9.</td></tr>
</table>
    <p>This directive controls whether <code class="program"><a href="../programs/httpd.html">httpd</a></code> may use the
    sendfile support from the kernel to transmit file contents to the client.
    By default, when the handling of a request requires no access
    to the data within a file -- for example, when delivering a
    static file -- Apache httpd uses sendfile to deliver the file contents
    without ever reading the file if the OS supports it.</p>

    <p>This sendfile mechanism avoids separate read and send operations,
    and buffer allocations. But on some platforms or within some
    filesystems, it is better to disable this feature to avoid
    operational problems:</p>

    <ul>
    <li>Some platforms may have broken sendfile support that the build
    system did not detect, especially if the binaries were built on
    another box and moved to such a machine with broken sendfile
    support.</li>
    <li>On Linux the use of sendfile triggers TCP-checksum
    offloading bugs on certain networking cards when using IPv6.</li>
    <li>On Linux on Itanium, sendfile may be unable to handle files
    over 2GB in size.</li>
    <li>With a network-mounted <code class="directive"><a href="#documentroot">DocumentRoot</a></code> (e.g., NFS, SMB, CIFS, FUSE),
    the kernel may be unable to serve the network file through
    its own cache.</li>
    </ul>

    <p>For server configurations that are not vulnerable to these problems,
    you may enable this feature by specifying:</p>

    <div class="example"><p><code>
      EnableSendfile On
    </code></p></div>

    <p>For network mounted files, this feature may be disabled explicitly
    for the offending files by specifying:</p>

    <div class="example"><p><code>
      &lt;Directory "/path-to-nfs-files"&gt;
      <span class="indent">
        EnableSendfile Off
      </span>
      &lt;/Directory&gt;
    </code></p></div>
    <p>Please note that the per-directory and .htaccess configuration
       of <code class="directive">EnableSendfile</code> is not supported by
       <code class="module"><a href="../mod/mod_cache_disk.html">mod_cache_disk</a></code>.
       Only global definition of <code class="directive">EnableSendfile</code>
       is taken into account by the module.
    </p>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="error" id="error">Directiva</a> <a name="Error" id="Error">Error</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Abort configuration parsing with a custom error message</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>Error <var>message</var></code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>2.3.9 and later</td></tr>
</table>
    <p>If an error can be detected within the configuration, this
    directive can be used to generate a custom error message, and halt
    configuration parsing.  The typical use is for reporting required
    modules which are missing from the configuration.</p>

    <div class="example"><h3>Example</h3><p><code>
      # ensure that mod_include is loaded<br />
      &lt;IfModule !include_module&gt;<br />
      Error mod_include is required by mod_foo.  Load it with LoadModule.<br />
      &lt;/IfModule&gt;<br />
      <br />
      # ensure that exactly one of SSL,NOSSL is defined<br />
      &lt;IfDefine SSL&gt;<br />
      &lt;IfDefine NOSSL&gt;<br />
      Error Both SSL and NOSSL are defined.  Define only one of them.<br />
      &lt;/IfDefine&gt;<br />
      &lt;/IfDefine&gt;<br />
      &lt;IfDefine !SSL&gt;<br />
      &lt;IfDefine !NOSSL&gt;<br />
      Error Either SSL or NOSSL must be defined.<br />
      &lt;/IfDefine&gt;<br />
      &lt;/IfDefine&gt;<br />
    </code></p></div>


</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="errordocument" id="errordocument">Directiva</a> <a name="ErrorDocument" id="ErrorDocument">ErrorDocument</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>What the server will return to the client
in case of an error</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>ErrorDocument <var>error-code</var> <var>document</var></code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>FileInfo</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>In the event of a problem or error, Apache httpd can be configured
    to do one of four things,</p>

    <ol>
      <li>output a simple hardcoded error message</li>

      <li>output a customized message</li>

      <li>redirect to a local <var>URL-path</var> to handle the
      problem/error</li>

      <li>redirect to an external <var>URL</var> to handle the
      problem/error</li>
    </ol>

    <p>The first option is the default, while options 2-4 are
    configured using the <code class="directive">ErrorDocument</code>
    directive, which is followed by the HTTP response code and a URL
    or a message. Apache httpd will sometimes offer additional information
    regarding the problem/error.</p>

    <p>URLs can begin with a slash (/) for local web-paths (relative
    to the <code class="directive"><a href="#documentroot">DocumentRoot</a></code>), or be a
    full URL which the client can resolve. Alternatively, a message
    can be provided to be displayed by the browser. Examples:</p>

    <div class="example"><p><code>
      ErrorDocument 500 http://foo.example.com/cgi-bin/tester<br />
      ErrorDocument 404 /cgi-bin/bad_urls.pl<br />
      ErrorDocument 401 /subscription_info.html<br />
      ErrorDocument 403 "Sorry can't allow you access today"
    </code></p></div>

    <p>Additionally, the special value <code>default</code> can be used
    to specify Apache httpd's simple hardcoded message.  While not required
    under normal circumstances, <code>default</code> will restore
    Apache httpd's simple hardcoded message for configurations that would
    otherwise inherit an existing <code class="directive">ErrorDocument</code>.</p>

    <div class="example"><p><code>
      ErrorDocument 404 /cgi-bin/bad_urls.pl<br /><br />
      &lt;Directory /web/docs&gt;<br />
      <span class="indent">
        ErrorDocument 404 default<br />
      </span>
      &lt;/Directory&gt;
    </code></p></div>

    <p>Note that when you specify an <code class="directive">ErrorDocument</code>
    that points to a remote URL (ie. anything with a method such as
    <code>http</code> in front of it), Apache HTTP Server will send a redirect to the
    client to tell it where to find the document, even if the
    document ends up being on the same server. This has several
    implications, the most important being that the client will not
    receive the original error status code, but instead will
    receive a redirect status code. This in turn can confuse web
    robots and other clients which try to determine if a URL is
    valid using the status code. In addition, if you use a remote
    URL in an <code>ErrorDocument 401</code>, the client will not
    know to prompt the user for a password since it will not
    receive the 401 status code. Therefore, <strong>if you use an
    <code>ErrorDocument 401</code> directive then it must refer to a local
    document.</strong></p>

    <p>Microsoft Internet Explorer (MSIE) will by default ignore
    server-generated error messages when they are "too small" and substitute
    its own "friendly" error messages. The size threshold varies depending on
    the type of error, but in general, if you make your error document
    greater than 512 bytes, then MSIE will show the server-generated
    error rather than masking it.  More information is available in
    Microsoft Knowledge Base article <a href="http://support.microsoft.com/default.aspx?scid=kb;en-us;Q294807">Q294807</a>.</p>

    <p>Although most error messages can be overriden, there are certain
    circumstances where the internal messages are used regardless of the
    setting of <code class="directive"><a href="#errordocument">ErrorDocument</a></code>.  In
    particular, if a malformed request is detected, normal request processing
    will be immediately halted and the internal error message returned.
    This is necessary to guard against security problems caused by
    bad requests.</p>
   
    <p>If you are using mod_proxy, you may wish to enable
    <code class="directive"><a href="../mod/mod_proxy.html#proxyerroroverride">ProxyErrorOverride</a></code> so that you can provide
    custom error messages on behalf of your Origin servers. If you don't enable ProxyErrorOverride,
    Apache httpd will not generate custom error documents for proxied content.</p>

<h3>Consulte también</h3>
<ul>
<li><a href="../custom-error.html">documentation of
    customizable responses</a></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="errorlog" id="errorlog">Directiva</a> <a name="ErrorLog" id="ErrorLog">ErrorLog</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Location where the server will log errors</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code> ErrorLog <var>file-path</var>|syslog[:<var>facility</var>]</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>ErrorLog logs/error_log (Unix) ErrorLog logs/error.log (Windows and OS/2)</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code class="directive">ErrorLog</code> directive sets the name of
    the file to which the server will log any errors it encounters. If
    the <var>file-path</var> is not absolute then it is assumed to be 
    relative to the <code class="directive"><a href="#serverroot">ServerRoot</a></code>.</p>

    <div class="example"><h3>Example</h3><p><code>
    ErrorLog /var/log/httpd/error_log
    </code></p></div>

    <p>If the <var>file-path</var>
    begins with a pipe character "<code>|</code>" then it is assumed to be a
    command to spawn to handle the error log.</p>

    <div class="example"><h3>Example</h3><p><code>
    ErrorLog "|/usr/local/bin/httpd_errors"
    </code></p></div>

    <p>See the notes on <a href="../logs.html#piped">piped logs</a> for
    more information.</p>

    <p>Using <code>syslog</code> instead of a filename enables logging
    via syslogd(8) if the system supports it. The default is to use
    syslog facility <code>local7</code>, but you can override this by
    using the <code>syslog:<var>facility</var></code> syntax where
    <var>facility</var> can be one of the names usually documented in
    syslog(1).  The facility is effectively global, and if it is changed
    in individual virtual hosts, the final facility specified affects the
    entire server.</p>

    <div class="example"><h3>Example</h3><p><code>
    ErrorLog syslog:user
    </code></p></div>

    <p>SECURITY: See the <a href="../misc/security_tips.html#serverroot">security tips</a>
    document for details on why your security could be compromised
    if the directory where log files are stored is writable by
    anyone other than the user that starts the server.</p>
    <div class="warning"><h3>Note</h3>
      <p>When entering a file path on non-Unix platforms, care should be taken
      to make sure that only forward slashed are used even though the platform
      may allow the use of back slashes. In general it is a good idea to always 
      use forward slashes throughout the configuration files.</p>
    </div>

<h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#loglevel">LogLevel</a></code></li>
<li><a href="../logs.html">Apache HTTP Server Log Files</a></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="errorlogformat" id="errorlogformat">Directiva</a> <a name="ErrorLogFormat" id="ErrorLogFormat">ErrorLogFormat</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Format specification for error log entries</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code> ErrorLog [connection|request] <var>format</var></code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in Apache httpd 2.3.9 and later</td></tr>
</table>
    <p><code class="directive">ErrorLogFormat</code> allows to specify what
    supplementary information is logged in the error log in addition to the
    actual log message.</p>

    <div class="example"><h3>Simple example</h3><p><code>
        ErrorLogFormat "[%t] [%l] [pid %P] %F: %E: [client %a] %M"
    </code></p></div>

    <p>Specifying <code>connection</code> or <code>request</code> as first
    paramter allows to specify additional formats, causing additional
    information to be logged when the first message is logged for a specific
    connection or request, respectivly. This additional information is only
    logged once per connection/request. If a connection or request is processed
    without causing any log message, the additional information is not logged
    either.</p>

    <p>It can happen that some format string items do not produce output.  For
    example, the Referer header is only present if the log message is
    associated to a request and the log message happens at a time when the
    Referer header has already been read from the client.  If no output is
    produced, the default behaviour is to delete everything from the preceeding
    space character to the next space character.  This means the log line is
    implicitly divided into fields on non-whitespace to whitespace transitions.
    If a format string item does not produce output, the whole field is
    ommitted.  For example, if the remote address <code>%a</code> in the log
    format <code>[%t] [%l] [%a] %M&nbsp;</code> is not available, the surrounding
    brackets are not logged either.  Space characters can be escaped with a
    backslash to prevent them from delimiting a field.  The combination '%&nbsp;'
    (percent space) is a zero-witdh field delimiter that does not produce any
    output.</p>

    <p>The above behaviour can be changed by adding modifiers to the format
    string item. A <code>-</code> (minus) modifier causes a minus to be logged if the
    respective item does not produce any output. In once-per-connection/request
    formats, it is also possible to use the <code>+</code> (plus) modifier. If an
    item with the plus modifier does not produce any output, the whole line is
    ommitted.</p>

    <p>A number as modifier can be used to assign a log severity level to a
    format item. The item will only be logged if the severity of the log
    message is not higher than the specified log severity level. The number can
    range from 1 (alert) over 4 (warn) and 7 (debug) to 15 (trace8).</p>

    <p>Some format string items accept additional parameters in braces.</p>

    <table class="bordered"><tr class="header"><th>Format&nbsp;String</th> <th>Description</th></tr>
<tr><td><code>%%</code></td>
        <td>The percent sign</td></tr>
<tr class="odd"><td><code>%...a</code></td>
        <td>Remote IP-address and port</td></tr>
<tr><td><code>%...A</code></td>
        <td>Local IP-address and port</td></tr>
<tr class="odd"><td><code>%...{name}e</code></td>
        <td>Request environment variable <code>name</code></td></tr>
<tr><td><code>%...E</code></td>
        <td>APR/OS error status code and string</td></tr>
<tr class="odd"><td><code>%...F</code></td>
        <td>Source file name and line number of the log call</td></tr>
<tr><td><code>%...{name}i</code></td>
        <td>Request header <code>name</code></td></tr>
<tr class="odd"><td><code>%...k</code></td>
        <td>Number of keep-alive requests on this connection</td></tr>
<tr><td><code>%...l</code></td>
        <td>Loglevel of the message</td></tr>
<tr class="odd"><td><code>%...L</code></td>
        <td>Log ID of the request</td></tr>
<tr><td><code>%...{c}L</code></td>
        <td>Log ID of the connection</td></tr>
<tr class="odd"><td><code>%...{C}L</code></td>
        <td>Log ID of the connection if used in connection scope, empty otherwise</td></tr>
<tr><td><code>%...m</code></td>
        <td>Name of the module logging the message</td></tr>
<tr class="odd"><td><code>%M</code></td>
        <td>The actual log message</td></tr>
<tr><td><code>%...{name}n</code></td>
        <td>Request note <code>name</code></td></tr>
<tr class="odd"><td><code>%...P</code></td>
        <td>Process ID of current process</td></tr>
<tr><td><code>%...T</code></td>
        <td>Thread ID of current thread</td></tr>
<tr class="odd"><td><code>%...t</code></td>
        <td>The current time</td></tr>
<tr><td><code>%...{u}t</code></td>
        <td>The current time including micro-seconds</td></tr>
<tr class="odd"><td><code>%...{cu}t</code></td>
        <td>The current time in compact ISO 8601 format, including
            micro-seconds</td></tr>
<tr><td><code>%...v</code></td>
        <td>The canonical <code class="directive"><a href="#servername">ServerName</a></code>
            of the current server.</td></tr>
<tr class="odd"><td><code>%...V</code></td>
        <td>The server name of the server serving the request according to the
            <code class="directive"><a href="#usecanonicalname">UseCanonicalName</a></code>
            setting.</td></tr>
<tr><td><code>\&nbsp;</code> (backslash space)</td>
        <td>Non-field delimiting space</td></tr>
<tr class="odd"><td><code>%&nbsp;</code> (percent space)</td>
        <td>Field delimiter (no output)</td></tr>
</table>

    <p>The log ID format <code>%L</code> produces a unique id for a connection
    or request. This can be used to correlate which log lines belong to the
    same connection or request, which request happens on which connection.
    A <code>%L</code> format string is also available in
    <code class="module"><a href="../mod/mod_log_config.html">mod_log_config</a></code>, to allow to correlate access log entries
    with error log lines. If <code class="module"><a href="../mod/mod_unique_id.html">mod_unique_id</a></code> is loaded, its
    unique id will be used as log ID for requests.</p>

    <div class="example"><h3>Example (somewhat similar to default format)</h3><p><code>
        ErrorLogFormat "[%{u}t] [%-m:%l] [pid %P] %7F: %E: [client\ %a]
        %M%&nbsp;,\&nbsp;referer\&nbsp;%{Referer}i"
    </code></p></div>

    <div class="example"><h3>Example (similar to the 2.2.x format)</h3><p><code>
        ErrorLogFormat "[%t] [%l] %7F: %E: [client\ %a]
        %M%&nbsp;,\&nbsp;referer\&nbsp;%{Referer}i"
    </code></p></div>

    <div class="example"><h3>Advanced example with request/connection log IDs</h3><p><code>
        ErrorLogFormat "[%{uc}t] [%-m:%-l] [R:%L] [C:%{C}L] %7F: %E: %M"<br />
        ErrorLogFormat request "[%{uc}t] [R:%L] Request %k on C:%{c}L pid:%P tid:%T"<br />
        ErrorLogFormat request "[%{uc}t] [R:%L] UA:'%+{User-Agent}i'"<br />
        ErrorLogFormat request "[%{uc}t] [R:%L] Referer:'%+{Referer}i'"<br />
        ErrorLogFormat connection "[%{uc}t] [C:%{c}L] local\ %a remote\ %A"<br />
    </code></p></div>


<h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#errorlog">ErrorLog</a></code></li>
<li><code class="directive"><a href="#loglevel">LogLevel</a></code></li>
<li><a href="../logs.html">Apache HTTP Server Log Files</a></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="extendedstatus" id="extendedstatus">Directiva</a> <a name="ExtendedStatus" id="ExtendedStatus">ExtendedStatus</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Keep track of extended status information for each 
request</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>ExtendedStatus On|Off</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>ExtendedStatus Off[*]</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>This option tracks additional data per worker about the
    currently executing request, and a utilization summary; you 
    can see these variables during runtime by configuring 
    <code class="module"><a href="../mod/mod_status.html">mod_status</a></code>.  Note that other modules may
    rely on this scoreboard.</p>

    <p>This setting applies to the entire server, and cannot be
    enabled or disabled on a virtualhost-by-virtualhost basis.
    The collection of extended status information can slow down
    the server.  Also note that this setting cannot be changed
    during a graceful restart.</p>

    <div class="note">
    <p>Note that loading <code class="module"><a href="../mod/mod_status.html">mod_status</a></code> will change 
    the default behavior to ExtendedStatus On, while other
    third party modules may do the same.  Such modules rely on
    collecting detailed information about the state of all workers.
    The default is changed by <code class="module"><a href="../mod/mod_status.html">mod_status</a></code> beginning
    with version 2.3.6; the previous default was always Off.</p>
    </div>


</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="fileetag" id="fileetag">Directiva</a> <a name="FileETag" id="FileETag">FileETag</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>File attributes used to create the ETag
HTTP response header for static files</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>FileETag <var>component</var> ...</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>FileETag INode MTime Size</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>FileInfo</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>
    The <code class="directive">FileETag</code> directive configures the file
    attributes that are used to create the <code>ETag</code> (entity
    tag) response header field when the document is based on a static file.
    (The <code>ETag</code> value is used in cache management to save
    network bandwidth.) The
    <code class="directive">FileETag</code> directive allows you to choose
    which of these -- if any -- should be used. The recognized keywords are:
    </p>

    <dl>
     <dt><strong>INode</strong></dt>
     <dd>The file's i-node number will be included in the calculation</dd>
     <dt><strong>MTime</strong></dt>
     <dd>The date and time the file was last modified will be included</dd>
     <dt><strong>Size</strong></dt>
     <dd>The number of bytes in the file will be included</dd>
     <dt><strong>All</strong></dt>
     <dd>All available fields will be used. This is equivalent to:
         <div class="example"><p><code>FileETag INode MTime Size</code></p></div></dd>
     <dt><strong>None</strong></dt>
     <dd>If a document is file-based, no <code>ETag</code> field will be
       included in the response</dd>
    </dl>

    <p>The <code>INode</code>, <code>MTime</code>, and <code>Size</code>
    keywords may be prefixed with either <code>+</code> or <code>-</code>,
    which allow changes to be made to the default setting inherited
    from a broader scope. Any keyword appearing without such a prefix
    immediately and completely cancels the inherited setting.</p>

    <p>If a directory's configuration includes
    <code>FileETag&nbsp;INode&nbsp;MTime&nbsp;Size</code>, and a
    subdirectory's includes <code>FileETag&nbsp;-INode</code>,
    the setting for that subdirectory (which will be inherited by
    any sub-subdirectories that don't override it) will be equivalent to
    <code>FileETag&nbsp;MTime&nbsp;Size</code>.</p>
    <div class="warning"><h3>Warning</h3>
    Do not change the default for directories or locations that have WebDAV
    enabled and use <code class="module"><a href="../mod/mod_dav_fs.html">mod_dav_fs</a></code> as a storage provider.
    <code class="module"><a href="../mod/mod_dav_fs.html">mod_dav_fs</a></code> uses <code>INode&nbsp;MTime&nbsp;Size</code>
    as a fixed format for <code>ETag</code> comparisons on conditional requests.
    These conditional requests will break if the <code>ETag</code> format is
    changed via <code class="directive">FileETag</code>.
    </div>
    <div class="note"><h3>Server Side Includes</h3>
    An ETag is not generated for responses parsed by <code class="module"><a href="../mod/mod_include.html">mod_include</a></code>, 
    since the response entity can change without a change of the INode, MTime, or Size 
    of the static file with embedded SSI directives.
    </div>


</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="files" id="files">Directiva</a> <a name="Files" id="Files">&lt;Files&gt;</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Contains directives that apply to matched
filenames</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>&lt;Files <var>filename</var>&gt; ... &lt;/Files&gt;</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>All</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code class="directive">&lt;Files&gt;</code> directive
    limits the scope of the enclosed directives by filename. It is comparable
    to the <code class="directive"><a href="#directory">&lt;Directory&gt;</a></code>
    and <code class="directive"><a href="#location">&lt;Location&gt;</a></code>
    directives. It should be matched with a <code>&lt;/Files&gt;</code>
    directive. The directives given within this section will be applied to
    any object with a basename (last component of filename) matching the
    specified filename. <code class="directive">&lt;Files&gt;</code>
    sections are processed in the order they appear in the
    configuration file, after the <code class="directive"><a href="#directory">&lt;Directory&gt;</a></code> sections and
    <code>.htaccess</code> files are read, but before <code class="directive"><a href="#location">&lt;Location&gt;</a></code> sections. Note
    that <code class="directive">&lt;Files&gt;</code> can be nested
    inside <code class="directive"><a href="#directory">&lt;Directory&gt;</a></code> sections to restrict the
    portion of the filesystem they apply to.</p>

    <p>The <var>filename</var> argument should include a filename, or
    a wild-card string, where <code>?</code> matches any single character,
    and <code>*</code> matches any sequences of characters.
    <a class="glossarylink" href="../glossary.html#regex" title="ver glosario">Regular expressions</a> 
    can also be used, with the addition of the
    <code>~</code> character. For example:</p>

    <div class="example"><p><code>
      &lt;Files ~ "\.(gif|jpe?g|png)$"&gt;
    </code></p></div>

    <p>would match most common Internet graphics formats. <code class="directive"><a href="#filesmatch">&lt;FilesMatch&gt;</a></code> is preferred,
    however.</p>

    <p>Note that unlike <code class="directive"><a href="#directory">&lt;Directory&gt;</a></code> and <code class="directive"><a href="#location">&lt;Location&gt;</a></code> sections, <code class="directive">&lt;Files&gt;</code> sections can be used inside
    <code>.htaccess</code> files. This allows users to control access to
    their own files, at a file-by-file level.</p>


<h3>Consulte también</h3>
<ul>
<li><a href="../sections.html">How &lt;Directory&gt;, &lt;Location&gt;
    and &lt;Files&gt; sections work</a> for an explanation of how these
    different sections are combined when a request is received</li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="filesmatch" id="filesmatch">Directiva</a> <a name="FilesMatch" id="FilesMatch">&lt;FilesMatch&gt;</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Contains directives that apply to regular-expression matched
filenames</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>&lt;FilesMatch <var>regex</var>&gt; ... &lt;/FilesMatch&gt;</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>All</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code class="directive">&lt;FilesMatch&gt;</code> directive
    limits the scope of the enclosed directives by filename, just as the
    <code class="directive"><a href="#files">&lt;Files&gt;</a></code> directive
    does. However, it accepts a <a class="glossarylink" href="../glossary.html#regex" title="ver glosario">regular 
    expression</a>. For example:</p>

    <div class="example"><p><code>
      &lt;FilesMatch "\.(gif|jpe?g|png)$"&gt;
    </code></p></div>

    <p>would match most common Internet graphics formats.</p>

<h3>Consulte también</h3>
<ul>
<li><a href="../sections.html">How &lt;Directory&gt;, &lt;Location&gt;
    and &lt;Files&gt; sections work</a> for an explanation of how these
    different sections are combined when a request is received</li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="forcetype" id="forcetype">Directiva</a> <a name="ForceType" id="ForceType">ForceType</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Forces all matching files to be served with the specified
media type in the HTTP Content-Type header field</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>ForceType <var>media-type</var>|None</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>FileInfo</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Moved to the core in Apache httpd 2.0</td></tr>
</table>
    <p>When placed into an <code>.htaccess</code> file or a
    <code class="directive"><a href="#directory">&lt;Directory&gt;</a></code>, or
    <code class="directive"><a href="#location">&lt;Location&gt;</a></code> or
    <code class="directive"><a href="#files">&lt;Files&gt;</a></code>
    section, this directive forces all matching files to be served
    with the content type identification given by
    <var>media-type</var>. For example, if you had a directory full of
    GIF files, but did not want to label them all with <code>.gif</code>,
    you might want to use:</p>

    <div class="example"><p><code>
      ForceType image/gif
    </code></p></div>

    <p>Note that this directive overrides other indirect media type
    associations defined in mime.types or via the
    <code class="directive"><a href="../mod/mod_mime.html#addtype">AddType</a></code>.</p>

    <p>You can also override more general
    <code class="directive">ForceType</code> settings
    by using the value of <code>None</code>:</p>

    <div class="example"><p><code>
      # force all files to be image/gif:<br />
      &lt;Location /images&gt;<br />
        <span class="indent">
          ForceType image/gif<br />
        </span>
      &lt;/Location&gt;<br />
      <br />
      # but normal mime-type associations here:<br />
      &lt;Location /images/mixed&gt;<br />
      <span class="indent">
        ForceType None<br />
      </span>
      &lt;/Location&gt;
    </code></p></div>

    <p>This directive primarily overrides the content types generated for
    static files served out of the filesystem.  For resources other than 
    static files, where the generator of the response typically specifies 
    a Content-Type, this directive has no effect.</p>


</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="gprofdir" id="gprofdir">Directiva</a> <a name="GprofDir" id="GprofDir">GprofDir</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Directory to write gmon.out profiling data to.  </td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>GprofDir <var>/tmp/gprof/</var>|<var>/tmp/gprof/</var>%</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>When the server has been compiled with gprof profiling support,
    <code class="directive">GprofDir</code> causes <code>gmon.out</code> files to
    be written to the specified directory when the process exits.  If the
    argument ends with a percent symbol ('%'), subdirectories are created
    for each process id.</p>

    <p>This directive currently only works with the <code class="module"><a href="../mod/prefork.html">prefork</a></code> 
    MPM.</p>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="hostnamelookups" id="hostnamelookups">Directiva</a> <a name="HostnameLookups" id="HostnameLookups">HostnameLookups</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Enables DNS lookups on client IP addresses</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>HostnameLookups On|Off|Double</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>HostnameLookups Off</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>This directive enables DNS lookups so that host names can be
    logged (and passed to CGIs/SSIs in <code>REMOTE_HOST</code>).
    The value <code>Double</code> refers to doing double-reverse
    DNS lookup. That is, after a reverse lookup is performed, a forward
    lookup is then performed on that result. At least one of the IP
    addresses in the forward lookup must match the original
    address. (In "tcpwrappers" terminology this is called
    <code>PARANOID</code>.)</p>

    <p>Regardless of the setting, when <code class="module"><a href="../mod/mod_authz_host.html">mod_authz_host</a></code> is
    used for controlling access by hostname, a double reverse lookup
    will be performed.  This is necessary for security. Note that the
    result of this double-reverse isn't generally available unless you
    set <code>HostnameLookups Double</code>. For example, if only
    <code>HostnameLookups On</code> and a request is made to an object
    that is protected by hostname restrictions, regardless of whether
    the double-reverse fails or not, CGIs will still be passed the
    single-reverse result in <code>REMOTE_HOST</code>.</p>

    <p>The default is <code>Off</code> in order to save the network
    traffic for those sites that don't truly need the reverse
    lookups done. It is also better for the end users because they
    don't have to suffer the extra latency that a lookup entails.
    Heavily loaded sites should leave this directive
    <code>Off</code>, since DNS lookups can take considerable
    amounts of time. The utility <code class="program"><a href="../programs/logresolve.html">logresolve</a></code>, compiled by
    default to the <code>bin</code> subdirectory of your installation
    directory, can be used to look up host names from logged IP addresses
    offline.</p>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="httpprotocoloptions" id="httpprotocoloptions">Directiva</a> <a name="HttpProtocolOptions" id="HttpProtocolOptions">HttpProtocolOptions</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Modify restrictions on HTTP Request Messages</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>HttpProtocolOptions [Strict|Unsafe] [RegisteredMethods|LenientMethods]
 [Allow0.9|Require1.0]</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>HttpProtocolOptions Strict LenientMethods Allow0.9</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>2.2.32 or 2.4.24 and later</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p></div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="if" id="if">Directiva</a> <a name="If" id="If">&lt;If&gt;</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Contains directives that apply only if a condition is
satisfied by a request at runtime</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>&lt;If <var>expression</var>&gt; ... &lt;/If&gt;</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>All</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code class="directive">&lt;If&gt;</code> directive
    evaluates an expression at runtime, and applies the enclosed
    directives if and only if the expression evaluates to true.
    For example:</p>

    <div class="example"><p><code>
        &lt;If "$req{Host} = ''"&gt;
    </code></p></div>

    <p>would match HTTP/1.0 requests without a <var>Host:</var> header.</p>

    <p>You may compare the value of any variable in the request headers
    ($req), response headers ($resp) or environment ($env) in your
    expression.</p>

    <p>Apart from <code>=</code>, <code>If</code> can use the <code>IN</code>
    operator to compare if the expression is in a given range:</p>

    <div class="example"><p><code>
        &lt;If %{REQUEST_METHOD} IN GET,HEAD,OPTIONS&gt;
    </code></p></div>


<h3>Consulte también</h3>
<ul>
<li><a href="../expr.html">Expressions in Apache HTTP Server</a>,
for a complete reference and more examples.</li>
<li><a href="../sections.html">How &lt;Directory&gt;, &lt;Location&gt;,
    &lt;Files&gt; sections work</a> for an explanation of how these
    different sections are combined when a request is received.
    <code class="directive">&lt;If&gt;</code> has the same precedence
    and usage as <code class="directive">&lt;Files&gt;</code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="ifdefine" id="ifdefine">Directiva</a> <a name="IfDefine" id="IfDefine">&lt;IfDefine&gt;</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Encloses directives that will be processed only
if a test is true at startup</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>&lt;IfDefine [!]<var>parameter-name</var>&gt; ...
    &lt;/IfDefine&gt;</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>All</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code>&lt;IfDefine <var>test</var>&gt;...&lt;/IfDefine&gt;
    </code> section is used to mark directives that are conditional. The
    directives within an <code class="directive">&lt;IfDefine&gt;</code>
    section are only processed if the <var>test</var> is true. If <var>
    test</var> is false, everything between the start and end markers is
    ignored.</p>

    <p>The <var>test</var> in the <code class="directive">&lt;IfDefine&gt;</code> section directive can be one of two forms:</p>

    <ul>
      <li><var>parameter-name</var></li>

      <li><code>!</code><var>parameter-name</var></li>
    </ul>

    <p>In the former case, the directives between the start and end
    markers are only processed if the parameter named
    <var>parameter-name</var> is defined. The second format reverses
    the test, and only processes the directives if
    <var>parameter-name</var> is <strong>not</strong> defined.</p>

    <p>The <var>parameter-name</var> argument is a define as given on the
    <code class="program"><a href="../programs/httpd.html">httpd</a></code> command line via <code>-D<var>parameter</var>
    </code> at the time the server was started or by the <code class="directive"><a href="#define">Define</a></code> directive.</p>

    <p><code class="directive">&lt;IfDefine&gt;</code> sections are
    nest-able, which can be used to implement simple
    multiple-parameter tests. Example:</p>

    <div class="example"><p><code>
      httpd -DReverseProxy -DUseCache -DMemCache ...<br />
      <br />
      # httpd.conf<br />
      &lt;IfDefine ReverseProxy&gt;<br />
      <span class="indent">
        LoadModule proxy_module   modules/mod_proxy.so<br />
        LoadModule proxy_http_module   modules/mod_proxy_http.so<br />
        &lt;IfDefine UseCache&gt;<br />
        <span class="indent">
          LoadModule cache_module   modules/mod_cache.so<br />
          &lt;IfDefine MemCache&gt;<br />
          <span class="indent">
            LoadModule mem_cache_module   modules/mod_mem_cache.so<br />
          </span>
          &lt;/IfDefine&gt;<br />
          &lt;IfDefine !MemCache&gt;<br />
          <span class="indent">
            LoadModule cache_disk_module   modules/mod_cache_disk.so<br />
          </span>
          &lt;/IfDefine&gt;
        </span>
        &lt;/IfDefine&gt;
      </span>
      &lt;/IfDefine&gt;
    </code></p></div>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="ifdirective" id="ifdirective">Directiva</a> <a name="IfDirective" id="IfDirective">&lt;IfDirective&gt;</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Encloses directives that are processed conditional on the
presence or absence of a specific directive</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>&lt;IfDirective [!]<var>directive-name</var>&gt; ...
    &lt;/IfDirective&gt;</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>All</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in 2.4.34 and later.</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p><h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#ifsection">&lt;IfSection&gt;</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="iffile" id="iffile">Directiva</a> <a name="IfFile" id="IfFile">&lt;IfFile&gt;</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Encloses directives that will be processed only
if file exists at startup</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>&lt;IfFile [!]<var>filename</var>&gt; ...
    &lt;/IfFile&gt;</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>All</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in 2.4.34 and later.</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p></div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="ifmodule" id="ifmodule">Directiva</a> <a name="IfModule" id="IfModule">&lt;IfModule&gt;</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Encloses directives that are processed conditional on the
presence or absence of a specific module</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>&lt;IfModule [!]<var>module-file</var>|<var>module-identifier</var>&gt; ...
    &lt;/IfModule&gt;</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>All</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Module identifiers are available in version 2.1 and
later.</td></tr>
</table>
    <p>The <code>&lt;IfModule <var>test</var>&gt;...&lt;/IfModule&gt;</code>
    section is used to mark directives that are conditional on the presence of
    a specific module. The directives within an <code class="directive">&lt;IfModule&gt;</code> section are only processed if the <var>test</var>
    is true. If <var>test</var> is false, everything between the start and
    end markers is ignored.</p>

    <p>The <var>test</var> in the <code class="directive">&lt;IfModule&gt;</code> section directive can be one of two forms:</p>

    <ul>
      <li><var>module</var></li>

      <li>!<var>module</var></li>
    </ul>

    <p>In the former case, the directives between the start and end
    markers are only processed if the module named <var>module</var>
    is included in Apache httpd -- either compiled in or
    dynamically loaded using <code class="directive"><a href="../mod/mod_so.html#loadmodule">LoadModule</a></code>. The second format reverses the test,
    and only processes the directives if <var>module</var> is
    <strong>not</strong> included.</p>

    <p>The <var>module</var> argument can be either the module identifier or
    the file name of the module, at the time it was compiled.  For example,
    <code>rewrite_module</code> is the identifier and
    <code>mod_rewrite.c</code> is the file name. If a module consists of
    several source files, use the name of the file containing the string
    <code>STANDARD20_MODULE_STUFF</code>.</p>

    <p><code class="directive">&lt;IfModule&gt;</code> sections are
    nest-able, which can be used to implement simple multiple-module
    tests.</p>

    <div class="note">This section should only be used if you need to have one
    configuration file that works whether or not a specific module
    is available. In normal operation, directives need not be
    placed in <code class="directive">&lt;IfModule&gt;</code>
    sections.</div>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="ifsection" id="ifsection">Directiva</a> <a name="IfSection" id="IfSection">&lt;IfSection&gt;</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Encloses directives that are processed conditional on the
presence or absence of a specific section directive</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>&lt;IfSection [!]<var>section-name</var>&gt; ...
    &lt;/IfSection&gt;</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>All</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in 2.4.34 and later.</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p><h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#ifdirective">&lt;IfDirective&gt;</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="include" id="include">Directiva</a> <a name="Include" id="Include">Include</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Includes other configuration files from within
the server configuration files</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>Include [<var>optional</var>|<var>strict</var>] <var>file-path</var>|<var>directory-path</var>|<var>wildcard</var></code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Wildcard matching available in 2.0.41 and later, directory
wildcard matching available in 2.3.6 and later</td></tr>
</table>
    <p>This directive allows inclusion of other configuration files
    from within the server configuration files.</p>

    <p>Shell-style (<code>fnmatch()</code>) wildcard characters can be used
    in the filename or directory parts of the path to include several files
    at once, in alphabetical order. In addition, if
    <code class="directive">Include</code> points to a directory, rather than a file,
    Apache httpd will read all files in that directory and any subdirectory.
    However, including entire directories is not recommended, because it is
    easy to accidentally leave temporary files in a directory that can cause
    <code class="program"><a href="../programs/httpd.html">httpd</a></code> to fail. Instead, we encourage you to use the
    wildcard syntax shown below, to include files that match a particular
    pattern, such as *.conf, for example.</p>

    <p>When a wildcard is specified for a <strong>file</strong> component of
    the path, and no file matches the wildcard, the
    <code class="directive"><a href="#include">Include</a></code>
    directive will be <strong>silently ignored</strong>. When a wildcard is
    specified for a <strong>directory</strong> component of the path, and
    no directory matches the wildcard, the
    <code class="directive"><a href="#include">Include</a></code> directive will
    <strong>fail with an error</strong> saying the directory cannot be found.
    </p>

    <p>For further control over the behaviour of the server when no files or
    directories match, prefix the path with the modifiers <var>optional</var>
    or <var>strict</var>. If <var>optional</var> is specified, any wildcard
    file or directory that does not match will be silently ignored. If
    <var>strict</var> is specified, any wildcard file or directory that does
    not match at least one file will cause server startup to fail.</p>

    <p>When a directory or file component of the path is
    specified exactly, and that directory or file does not exist,
    <code class="directive"><a href="#include">Include</a></code> directive will fail with an
    error saying the file or directory cannot be found.</p>

    <p>The file path specified may be an absolute path, or may be relative 
    to the <code class="directive"><a href="#serverroot">ServerRoot</a></code> directory.</p>

    <p>Examples:</p>

    <div class="example"><p><code>
      Include /usr/local/apache2/conf/ssl.conf<br />
      Include /usr/local/apache2/conf/vhosts/*.conf
    </code></p></div>

    <p>Or, providing paths relative to your <code class="directive"><a href="#serverroot">ServerRoot</a></code> directory:</p>

    <div class="example"><p><code>
      Include conf/ssl.conf<br />
      Include conf/vhosts/*.conf
    </code></p></div>

    <p>Wildcards may be included in the directory or file portion of the
    path. In the following example, the server will fail to load if no
    directories match conf/vhosts/*, but will load successfully if no
    files match *.conf.</p>
  
    <div class="example"><p><code>
      Include conf/vhosts/*/vhost.conf<br />
      Include conf/vhosts/*/*.conf
    </code></p></div>

    <p>In this example, the server will fail to load if either
    conf/vhosts/* matches no directories, or if *.conf matches no files:</p>

    <div class="example"><p><code>
      Include strict conf/vhosts/*/*.conf
    </code></p></div>
  
    <p>In this example, the server load successfully if either conf/vhosts/*
    matches no directories, or if *.conf matches no files:</p>

    <div class="example"><p><code>
      Include optional conf/vhosts/*/*.conf
    </code></p></div>


<h3>Consulte también</h3>
<ul>
<li><code class="program"><a href="../programs/apachectl.html">apachectl</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="includeoptional" id="includeoptional">Directiva</a> <a name="IncludeOptional" id="IncludeOptional">IncludeOptional</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Includes other configuration files from within
the server configuration files</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>IncludeOptional <var>file-path</var>|<var>directory-path</var>|<var>wildcard</var></code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in 2.3.6 and later. Not existent file paths without wildcards
               do not cause SyntaxError after 2.4.30</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p><h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#include">Include</a></code></li>
<li><code class="program"><a href="../programs/apachectl.html">apachectl</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="keepalive" id="keepalive">Directiva</a> <a name="KeepAlive" id="KeepAlive">KeepAlive</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Enables HTTP persistent connections</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>KeepAlive On|Off</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>KeepAlive On</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The Keep-Alive extension to HTTP/1.0 and the persistent
    connection feature of HTTP/1.1 provide long-lived HTTP sessions
    which allow multiple requests to be sent over the same TCP
    connection. In some cases this has been shown to result in an
    almost 50% speedup in latency times for HTML documents with
    many images. To enable Keep-Alive connections, set
    <code>KeepAlive On</code>.</p>

    <p>For HTTP/1.0 clients, Keep-Alive connections will only be
    used if they are specifically requested by a client. In
    addition, a Keep-Alive connection with an HTTP/1.0 client can
    only be used when the length of the content is known in
    advance. This implies that dynamic content such as CGI output,
    SSI pages, and server-generated directory listings will
    generally not use Keep-Alive connections to HTTP/1.0 clients.
    For HTTP/1.1 clients, persistent connections are the default
    unless otherwise specified. If the client requests it, chunked
    encoding will be used in order to send content of unknown
    length over persistent connections.</p>

    <p>When a client uses a Keep-Alive connection it will be counted
    as a single "request" for the <code class="directive"><a href="../mod/mpm_common.html#maxconnectionsperchild">MaxConnectionsPerChild</a></code> directive, regardless
    of how many requests are sent using the connection.</p>

<h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#maxkeepaliverequests">MaxKeepAliveRequests</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="keepalivetimeout" id="keepalivetimeout">Directiva</a> <a name="KeepAliveTimeout" id="KeepAliveTimeout">KeepAliveTimeout</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Amount of time the server will wait for subsequent
requests on a persistent connection</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>KeepAliveTimeout <var>num</var>[ms]</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>KeepAliveTimeout 5</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Specifying a value in milliseconds is available in 
Apache httpd 2.3.2 and later</td></tr>
</table>
    <p>The number of seconds Apache httpd will wait for a subsequent
    request before closing the connection. By adding a postfix of ms the
    timeout can be also set in milliseconds. Once a request has been
    received, the timeout value specified by the
    <code class="directive"><a href="#timeout">Timeout</a></code> directive applies.</p>

    <p>Setting <code class="directive">KeepAliveTimeout</code> to a high value
    may cause performance problems in heavily loaded servers. The
    higher the timeout, the more server processes will be kept
    occupied waiting on connections with idle clients.</p>
    
    <p>In a name-based virtual host context, the value of the first
    defined virtual host (the default host) in a set of <code class="directive"><a href="#namevirtualhost">NameVirtualHost</a></code> will be used.
    The other values will be ignored.</p>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="limit" id="limit">Directiva</a> <a name="Limit" id="Limit">&lt;Limit&gt;</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Restrict enclosed access controls to only certain HTTP
methods</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>&lt;Limit <var>method</var> [<var>method</var>] ... &gt; ...
    &lt;/Limit&gt;</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>AuthConfig, Limit</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>Access controls are normally effective for
    <strong>all</strong> access methods, and this is the usual
    desired behavior. <strong>In the general case, access control
    directives should not be placed within a
    <code class="directive">&lt;Limit&gt;</code> section.</strong></p>

    <p>The purpose of the <code class="directive">&lt;Limit&gt;</code>
    directive is to restrict the effect of the access controls to the
    nominated HTTP methods. For all other methods, the access
    restrictions that are enclosed in the <code class="directive">&lt;Limit&gt;</code> bracket <strong>will have no
    effect</strong>. The following example applies the access control
    only to the methods <code>POST</code>, <code>PUT</code>, and
    <code>DELETE</code>, leaving all other methods unprotected:</p>

    <div class="example"><p><code>
      &lt;Limit POST PUT DELETE&gt;<br />
      <span class="indent">
        Require valid-user<br />
      </span>
      &lt;/Limit&gt;
    </code></p></div>

    <p>The method names listed can be one or more of: <code>GET</code>,
    <code>POST</code>, <code>PUT</code>, <code>DELETE</code>,
    <code>CONNECT</code>, <code>OPTIONS</code>,
    <code>PATCH</code>, <code>PROPFIND</code>, <code>PROPPATCH</code>,
    <code>MKCOL</code>, <code>COPY</code>, <code>MOVE</code>,
    <code>LOCK</code>, and <code>UNLOCK</code>. <strong>The method name is
    case-sensitive.</strong> If <code>GET</code> is used it will also
    restrict <code>HEAD</code> requests. The <code>TRACE</code> method
    cannot be limited (see <code class="directive"><a href="#traceenable">TraceEnable</a></code>).</p>

    <div class="warning">A <code class="directive"><a href="#limitexcept">&lt;LimitExcept&gt;</a></code> section should always be
    used in preference to a <code class="directive">&lt;Limit&gt;</code>
    section when restricting access, since a <code class="directive"><a href="#limitexcept">&lt;LimitExcept&gt;</a></code> section provides protection
    against arbitrary methods.</div>

    <p>The <code class="directive">&lt;Limit&gt;</code> and
    <code class="directive"><a href="#limitexcept">&lt;LimitExcept&gt;</a></code>
    directives may be nested.  In this case, each successive level of
    <code class="directive">&lt;Limit&gt;</code> or <code class="directive"><a href="#limitexcept">&lt;LimitExcept&gt;</a></code> directives must
    further restrict the set of methods to which access controls apply.</p>

    <div class="warning">When using
    <code class="directive">&lt;Limit&gt;</code> or
    <code class="directive">&lt;LimitExcept&gt;</code> directives with
    the <code class="directive"><a href="../mod/mod_authz_core.html#require">Require</a></code> directive,
    note that the first <code class="directive"><a href="../mod/mod_authz_core.html#require">Require</a></code>
    to succeed authorizes the request, regardless of the presence of other
    <code class="directive"><a href="../mod/mod_authz_core.html#require">Require</a></code> directives.</div>

    <p>For example, given the following configuration, all users will
    be authorized for <code>POST</code> requests, and the
    <code>Require group editors</code> directive will be ignored
    in all cases:</p>

    <div class="example"><p><code>
      &lt;LimitExcept GET&gt;
      <span class="indent">
        Require valid-user
      </span> 
      &lt;/LimitExcept&gt;<br />
      &lt;Limit POST&gt;
      <span class="indent">
        Require group editors
      </span> 
      &lt;/Limit&gt;
    </code></p></div>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="limitexcept" id="limitexcept">Directiva</a> <a name="LimitExcept" id="LimitExcept">&lt;LimitExcept&gt;</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Restrict access controls to all HTTP methods
except the named ones</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>&lt;LimitExcept <var>method</var> [<var>method</var>] ... &gt; ...
    &lt;/LimitExcept&gt;</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>AuthConfig, Limit</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p><code class="directive">&lt;LimitExcept&gt;</code> and
    <code>&lt;/LimitExcept&gt;</code> are used to enclose
    a group of access control directives which will then apply to any
    HTTP access method <strong>not</strong> listed in the arguments;
    i.e., it is the opposite of a <code class="directive"><a href="#limit">&lt;Limit&gt;</a></code> section and can be used to control
    both standard and nonstandard/unrecognized methods. See the
    documentation for <code class="directive"><a href="#limit">&lt;Limit&gt;</a></code> for more details.</p>

    <p>For example:</p>

    <div class="example"><p><code>
      &lt;LimitExcept POST GET&gt;<br />
      <span class="indent">
        Require valid-user<br />
      </span>
      &lt;/LimitExcept&gt;
    </code></p></div>


</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="limitinternalrecursion" id="limitinternalrecursion">Directiva</a> <a name="LimitInternalRecursion" id="LimitInternalRecursion">LimitInternalRecursion</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Determine maximum number of internal redirects and nested
subrequests</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>LimitInternalRecursion <var>number</var> [<var>number</var>]</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>LimitInternalRecursion 10</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in Apache httpd 2.0.47 and later</td></tr>
</table>
    <p>An internal redirect happens, for example, when using the <code class="directive"><a href="../mod/mod_actions.html#action">Action</a></code> directive, which internally
    redirects the original request to a CGI script. A subrequest is Apache httpd's
    mechanism to find out what would happen for some URI if it were requested.
    For example, <code class="module"><a href="../mod/mod_dir.html">mod_dir</a></code> uses subrequests to look for the
    files listed in the <code class="directive"><a href="../mod/mod_dir.html#directoryindex">DirectoryIndex</a></code>
    directive.</p>

    <p><code class="directive">LimitInternalRecursion</code> prevents the server
    from crashing when entering an infinite loop of internal redirects or
    subrequests. Such loops are usually caused by misconfigurations.</p>

    <p>The directive stores two different limits, which are evaluated on
    per-request basis. The first <var>number</var> is the maximum number of
    internal redirects, that may follow each other. The second <var>number</var>
    determines, how deep subrequests may be nested. If you specify only one
    <var>number</var>, it will be assigned to both limits.</p>

    <div class="example"><h3>Example</h3><p><code>
      LimitInternalRecursion 5
    </code></p></div>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="limitrequestbody" id="limitrequestbody">Directiva</a> <a name="LimitRequestBody" id="LimitRequestBody">LimitRequestBody</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Restricts the total size of the HTTP request body sent
from the client</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>LimitRequestBody <var>bytes</var></code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>LimitRequestBody 0</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>All</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>This directive specifies the number of <var>bytes</var> from 0
    (meaning unlimited) to 2147483647 (2GB) that are allowed in a
    request body. See the note below for the limited applicability
    to proxy requests.</p>

    <p>The <code class="directive">LimitRequestBody</code> directive allows
    the user to set a limit on the allowed size of an HTTP request
    message body within the context in which the directive is given
    (server, per-directory, per-file or per-location). If the client
    request exceeds that limit, the server will return an error
    response instead of servicing the request. The size of a normal
    request message body will vary greatly depending on the nature of
    the resource and the methods allowed on that resource. CGI scripts
    typically use the message body for retrieving form information.
    Implementations of the <code>PUT</code> method will require
    a value at least as large as any representation that the server
    wishes to accept for that resource.</p>

    <p>This directive gives the server administrator greater
    control over abnormal client request behavior, which may be
    useful for avoiding some forms of denial-of-service
    attacks.</p>

    <p>If, for example, you are permitting file upload to a particular
    location, and wish to limit the size of the uploaded file to 100K,
    you might use the following directive:</p>

    <div class="example"><p><code>
      LimitRequestBody 102400
    </code></p></div>
    
    <div class="note"><p>For a full description of how this directive is interpreted by 
    proxy requests, see the <code class="module"><a href="../mod/mod_proxy.html">mod_proxy</a></code> documentation.</p>
    </div>


</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="limitrequestfields" id="limitrequestfields">Directiva</a> <a name="LimitRequestFields" id="LimitRequestFields">LimitRequestFields</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Limits the number of HTTP request header fields that
will be accepted from the client</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>LimitRequestFields <var>number</var></code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>LimitRequestFields 100</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p><var>Number</var> is an integer from 0 (meaning unlimited) to
    32767. The default value is defined by the compile-time
    constant <code>DEFAULT_LIMIT_REQUEST_FIELDS</code> (100 as
    distributed).</p>

    <p>The <code class="directive">LimitRequestFields</code> directive allows
    the server administrator to modify the limit on the number of
    request header fields allowed in an HTTP request. A server needs
    this value to be larger than the number of fields that a normal
    client request might include. The number of request header fields
    used by a client rarely exceeds 20, but this may vary among
    different client implementations, often depending upon the extent
    to which a user has configured their browser to support detailed
    content negotiation. Optional HTTP extensions are often expressed
    using request header fields.</p>

    <p>This directive gives the server administrator greater
    control over abnormal client request behavior, which may be
    useful for avoiding some forms of denial-of-service attacks.
    The value should be increased if normal clients see an error
    response from the server that indicates too many fields were
    sent in the request.</p>

    <p>For example:</p>

    <div class="example"><p><code>
      LimitRequestFields 50
    </code></p></div>

     <div class="warning"><h3>Warning</h3>
     <p> When name-based virtual hosting is used, the value for this 
     directive is taken from the default (first-listed) virtual host for the
     <code class="directive">NameVirtualHost</code> the connection was mapped to.</p>
     </div>


</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="limitrequestfieldsize" id="limitrequestfieldsize">Directiva</a> <a name="LimitRequestFieldSize" id="LimitRequestFieldSize">LimitRequestFieldSize</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Limits the size of the HTTP request header allowed from the
client</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>LimitRequestFieldSize <var>bytes</var></code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>LimitRequestFieldSize 8190</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>This directive specifies the number of <var>bytes</var>
    that will be allowed in an HTTP request header.</p>

    <p>The <code class="directive">LimitRequestFieldSize</code> directive
    allows the server administrator to reduce or increase the limit 
    on the allowed size of an HTTP request header field. A server
    needs this value to be large enough to hold any one header field 
    from a normal client request. The size of a normal request header 
    field will vary greatly among different client implementations, 
    often depending upon the extent to which a user has configured
    their browser to support detailed content negotiation. SPNEGO
    authentication headers can be up to 12392 bytes.</p>

    <p>This directive gives the server administrator greater
    control over abnormal client request behavior, which may be
    useful for avoiding some forms of denial-of-service attacks.</p>

    <p>For example:</p>

    <div class="example"><p><code>
      LimitRequestFieldSize 4094
    </code></p></div>

    <div class="note">Under normal conditions, the value should not be changed from
    the default.</div>

    <div class="warning"><h3>Warning</h3>
    <p> When name-based virtual hosting is used, the value for this 
    directive is taken from the default (first-listed) virtual host for the
    <code class="directive">NameVirtualHost</code> the connection was mapped to.</p>
    </div>


</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="limitrequestline" id="limitrequestline">Directiva</a> <a name="LimitRequestLine" id="LimitRequestLine">LimitRequestLine</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Limit the size of the HTTP request line that will be accepted
from the client</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>LimitRequestLine <var>bytes</var></code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>LimitRequestLine 8190</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>This directive sets the number of <var>bytes</var> that will be 
    allowed on the HTTP request-line.</p>

    <p>The <code class="directive">LimitRequestLine</code> directive allows
    the server administrator to reduce or increase the limit on the allowed size
    of a client's HTTP request-line. Since the request-line consists of the
    HTTP method, URI, and protocol version, the
    <code class="directive">LimitRequestLine</code> directive places a
    restriction on the length of a request-URI allowed for a request
    on the server. A server needs this value to be large enough to
    hold any of its resource names, including any information that
    might be passed in the query part of a <code>GET</code> request.</p>

    <p>This directive gives the server administrator greater
    control over abnormal client request behavior, which may be
    useful for avoiding some forms of denial-of-service attacks.</p>

    <p>For example:</p>

    <div class="example"><p><code>
      LimitRequestLine 4094
    </code></p></div>

    <div class="note">Under normal conditions, the value should not be changed from
    the default.</div>

    <div class="warning"><h3>Warning</h3>
    <p> When name-based virtual hosting is used, the value for this 
    directive is taken from the default (first-listed) virtual host for the
    <code class="directive">NameVirtualHost</code> the connection was mapped to.</p>
    </div>


</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="limitxmlrequestbody" id="limitxmlrequestbody">Directiva</a> <a name="LimitXMLRequestBody" id="LimitXMLRequestBody">LimitXMLRequestBody</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Limits the size of an XML-based request body</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>LimitXMLRequestBody <var>bytes</var></code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>LimitXMLRequestBody 1000000</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>All</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>Limit (in bytes) on maximum size of an XML-based request
    body. A value of <code>0</code> will disable any checking.</p>

    <p>Example:</p>

    <div class="example"><p><code>
      LimitXMLRequestBody 0
    </code></p></div>


</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="location" id="location">Directiva</a> <a name="Location" id="Location">&lt;Location&gt;</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Applies the enclosed directives only to matching
URLs</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>&lt;Location
    <var>URL-path</var>|<var>URL</var>&gt; ... &lt;/Location&gt;</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code class="directive">&lt;Location&gt;</code> directive
    limits the scope of the enclosed directives by URL. It is similar to the
    <code class="directive"><a href="#directory">&lt;Directory&gt;</a></code>
    directive, and starts a subsection which is terminated with a
    <code>&lt;/Location&gt;</code> directive. <code class="directive">&lt;Location&gt;</code> sections are processed in the
    order they appear in the configuration file, after the <code class="directive"><a href="#directory">&lt;Directory&gt;</a></code> sections and
    <code>.htaccess</code> files are read, and after the <code class="directive"><a href="#files">&lt;Files&gt;</a></code> sections.</p>

    <p><code class="directive">&lt;Location&gt;</code> sections operate
    completely outside the filesystem.  This has several consequences.
    Most importantly, <code class="directive">&lt;Location&gt;</code>
    directives should not be used to control access to filesystem
    locations.  Since several different URLs may map to the same
    filesystem location, such access controls may by circumvented.</p>

    <p>The enclosed directives will be applied to the request if the path component
    of the URL meets <em>any</em> of the following criteria:
    </p>
    <ul>
      <li>The specified location matches exactly the path component of the URL.
      </li>
      <li>The specified location, which ends in a forward slash, is a prefix 
      of the path component of the URL (treated as a context root).
      </li>
      <li>The specified location, with the addition of a trailing slash, is a 
      prefix of the path component of the URL (also treated as a context root).
      </li>
    </ul>
    <p>
    In the example below, where no trailing slash is used, requests to 
    /private1, /private1/ and /private1/file.txt will have the enclosed
    directives applied, but /private1other would not. 
    </p>
    <div class="example"><p><code>
      &lt;Location /private1&gt;
          ...
    </code></p></div>
    <p>
    In the example below, where a trailing slash is used, requests to 
    /private2/ and /private2/file.txt will have the enclosed
    directives applied, but /private2 and /private2other would not. 
    </p>
    <div class="example"><p><code>
      &lt;Location /private2<em>/</em>&gt;
          ...
    </code></p></div>

    <div class="note"><h3>When to use <code class="directive">&lt;Location&gt;</code></h3>

    <p>Use <code class="directive">&lt;Location&gt;</code> to apply
    directives to content that lives outside the filesystem.  For
    content that lives in the filesystem, use <code class="directive"><a href="#directory">&lt;Directory&gt;</a></code> and <code class="directive"><a href="#files">&lt;Files&gt;</a></code>.  An exception is
    <code>&lt;Location /&gt;</code>, which is an easy way to 
    apply a configuration to the entire server.</p>
    </div>

    <p>For all origin (non-proxy) requests, the URL to be matched is a
    URL-path of the form <code>/path/</code>.  <em>No scheme, hostname,
    port, or query string may be included.</em>  For proxy requests, the
    URL to be matched is of the form
    <code>scheme://servername/path</code>, and you must include the
    prefix.</p>

    <p>The URL may use wildcards. In a wild-card string, <code>?</code> matches
    any single character, and <code>*</code> matches any sequences of
    characters. Neither wildcard character matches a / in the URL-path.</p>

    <p><a class="glossarylink" href="../glossary.html#regex" title="ver glosario">Regular expressions</a>
    can also be used, with the addition of the <code>~</code> 
    character. For example:</p>

    <div class="example"><p><code>
      &lt;Location ~ "/(extra|special)/data"&gt;
    </code></p></div>

    <p>would match URLs that contained the substring <code>/extra/data</code>
    or <code>/special/data</code>. The directive <code class="directive"><a href="#locationmatch">&lt;LocationMatch&gt;</a></code> behaves
    identical to the regex version of <code class="directive">&lt;Location&gt;</code>, and is preferred, for the
    simple reason that <code>~</code> is hard to distinguish from
    <code>-</code> in many fonts.</p>

    <p>The <code class="directive">&lt;Location&gt;</code>
    functionality is especially useful when combined with the
    <code class="directive"><a href="#sethandler">SetHandler</a></code>
    directive. For example, to enable status requests, but allow them
    only from browsers at <code>example.com</code>, you might use:</p>

    <div class="example"><p><code>
      &lt;Location /status&gt;<br />
      <span class="indent">
        SetHandler server-status<br />
        Require host example.com<br />
      </span>
      &lt;/Location&gt;
    </code></p></div>

    <div class="note"><h3>Note about / (slash)</h3>
      <p>The slash character has special meaning depending on where in a
      URL it appears. People may be used to its behavior in the filesystem
      where multiple adjacent slashes are frequently collapsed to a single
      slash (<em>i.e.</em>, <code>/home///foo</code> is the same as
      <code>/home/foo</code>). In URL-space this is not necessarily true.
      The <code class="directive"><a href="#locationmatch">&lt;LocationMatch&gt;</a></code>
      directive and the regex version of <code class="directive">&lt;Location&gt;</code> require you to explicitly specify multiple
      slashes if that is your intention.</p>

      <p>For example, <code>&lt;LocationMatch ^/abc&gt;</code> would match
      the request URL <code>/abc</code> but not the request URL <code>
      //abc</code>. The (non-regex) <code class="directive">&lt;Location&gt;</code> directive behaves similarly when used for
      proxy requests. But when (non-regex) <code class="directive">&lt;Location&gt;</code> is used for non-proxy requests it will
      implicitly match multiple slashes with a single slash. For example,
      if you specify <code>&lt;Location /abc/def&gt;</code> and the
      request is to <code>/abc//def</code> then it will match.</p>
    </div>

<h3>Consulte también</h3>
<ul>
<li><a href="../sections.html">How &lt;Directory&gt;, &lt;Location&gt;
    and &lt;Files&gt; sections work</a> for an explanation of how these
    different sections are combined when a request is received.</li>
<li><code class="directive"><a href="#locationmatch">LocationMatch</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="locationmatch" id="locationmatch">Directiva</a> <a name="LocationMatch" id="LocationMatch">&lt;LocationMatch&gt;</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Applies the enclosed directives only to regular-expression
matching URLs</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>&lt;LocationMatch
    <var>regex</var>&gt; ... &lt;/LocationMatch&gt;</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code class="directive">&lt;LocationMatch&gt;</code> directive
    limits the scope of the enclosed directives by URL, in an identical manner
    to <code class="directive"><a href="#location">&lt;Location&gt;</a></code>. However,
    it takes a <a class="glossarylink" href="../glossary.html#regex" title="ver glosario">regular expression</a>
    as an argument instead of a simple string. For example:</p>

    <div class="example"><p><code>
      &lt;LocationMatch "/(extra|special)/data"&gt;
    </code></p></div>

    <p>would match URLs that contained the substring <code>/extra/data</code>
    or <code>/special/data</code>.</p>

<h3>Consulte también</h3>
<ul>
<li><a href="../sections.html">How &lt;Directory&gt;, &lt;Location&gt;
    and &lt;Files&gt; sections work</a> for an explanation of how these
    different sections are combined when a request is received</li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="loglevel" id="loglevel">Directiva</a> <a name="LogLevel" id="LogLevel">LogLevel</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Controls the verbosity of the ErrorLog</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>LogLevel [<var>module</var>:]<var>level</var>
    [<var>module</var>:<var>level</var>] ...
</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>LogLevel warn</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Per-module and per-directory configuration is available in
    Apache HTTP Server 2.3.6 and later</td></tr>
</table>
    <p><code class="directive">LogLevel</code> adjusts the verbosity of the
    messages recorded in the error logs (see <code class="directive"><a href="#errorlog">ErrorLog</a></code> directive). The following
    <var>level</var>s are available, in order of decreasing
    significance:</p>

    <table class="bordered">
    
      <tr>
        <th><strong>Level</strong> </th>

        <th><strong>Description</strong> </th>

        <th><strong>Example</strong> </th>
      </tr>

      <tr>
        <td><code>emerg</code> </td>

        <td>Emergencies - system is unusable.</td>

        <td>"Child cannot open lock file. Exiting"</td>
      </tr>

      <tr>
        <td><code>alert</code> </td>

        <td>Action must be taken immediately.</td>

        <td>"getpwuid: couldn't determine user name from uid"</td>
      </tr>

      <tr>
        <td><code>crit</code> </td>

        <td>Critical Conditions.</td>

        <td>"socket: Failed to get a socket, exiting child"</td>
      </tr>

      <tr>
        <td><code>error</code> </td>

        <td>Error conditions.</td>

        <td>"Premature end of script headers"</td>
      </tr>

      <tr>
        <td><code>warn</code> </td>

        <td>Warning conditions.</td>

        <td>"child process 1234 did not exit, sending another
        SIGHUP"</td>
      </tr>

      <tr>
        <td><code>notice</code> </td>

        <td>Normal but significant condition.</td>

        <td>"httpd: caught SIGBUS, attempting to dump core in
        ..."</td>
      </tr>

      <tr>
        <td><code>info</code> </td>

        <td>Informational.</td>

        <td>"Server seems busy, (you may need to increase
        StartServers, or Min/MaxSpareServers)..."</td>
      </tr>

      <tr>
        <td><code>debug</code> </td>

        <td>Debug-level messages</td>

        <td>"Opening config file ..."</td>
      </tr>
      <tr>
        <td><code>trace1</code> </td>

        <td>Trace messages</td>

        <td>"proxy: FTP: control connection complete"</td>
      </tr>
      <tr>
        <td><code>trace2</code> </td>

        <td>Trace messages</td>

        <td>"proxy: CONNECT: sending the CONNECT request to the remote proxy"</td>
      </tr>
      <tr>
        <td><code>trace3</code> </td>

        <td>Trace messages</td>

        <td>"openssl: Handshake: start"</td>
      </tr>
      <tr>
        <td><code>trace4</code> </td>

        <td>Trace messages</td>

        <td>"read from buffered SSL brigade, mode 0, 17 bytes"</td>
      </tr>
      <tr>
        <td><code>trace5</code> </td>

        <td>Trace messages</td>

        <td>"map lookup FAILED: map=rewritemap key=keyname"</td>
      </tr>
      <tr>
        <td><code>trace6</code> </td>

        <td>Trace messages</td>

        <td>"cache lookup FAILED, forcing new map lookup"</td>
      </tr>
      <tr>
        <td><code>trace7</code> </td>

        <td>Trace messages, dumping large amounts of data</td>

        <td>"| 0000: 02 23 44 30 13 40 ac 34 df 3d bf 9a 19 49 39 15 |"</td>
      </tr>
      <tr>
        <td><code>trace8</code> </td>

        <td>Trace messages, dumping large amounts of data</td>

        <td>"| 0000: 02 23 44 30 13 40 ac 34 df 3d bf 9a 19 49 39 15 |"</td>
      </tr>
    </table>

    <p>When a particular level is specified, messages from all
    other levels of higher significance will be reported as well.
    <em>E.g.</em>, when <code>LogLevel info</code> is specified,
    then messages with log levels of <code>notice</code> and
    <code>warn</code> will also be posted.</p>

    <p>Using a level of at least <code>crit</code> is
    recommended.</p>

    <p>For example:</p>

    <div class="example"><p><code>
      LogLevel notice
    </code></p></div>

    <div class="note"><h3>Note</h3>
      <p>When logging to a regular file messages of the level
      <code>notice</code> cannot be suppressed and thus are always
      logged. However, this doesn't apply when logging is done
      using <code>syslog</code>.</p>
    </div>

    <p>Specifying a level without a module name will reset the level
    for all modules to that level.  Specifying a level with a module
    name will set the level for that module only. It is possible to
    use the module source file name, the module identifier, or the
    module identifier with the trailing <code>_module</code> omitted
    as module specification. This means the following three specifications
    are equivalent:</p>

    <div class="example"><p><code>
      LogLevel info ssl:warn<br />
      LogLevel info mod_ssl.c:warn<br />
      LogLevel info ssl_module:warn<br />
    </code></p></div>

    <p>It is also possible to change the level per directory:</p>

    <div class="example"><p><code>
        LogLevel info<br />
        &lt;Directory /usr/local/apache/htdocs/app&gt;<br />
        &nbsp; LogLevel debug<br />
        &lt;/Files&gt;
    </code></p></div>

    <div class="note">
        Per directory loglevel configuration only affects messages that are
	logged after the request has been parsed and that are associated with
	the request. Log messages which are associated with the connection or
	the server are not affected.
    </div>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="maxkeepaliverequests" id="maxkeepaliverequests">Directiva</a> <a name="MaxKeepAliveRequests" id="MaxKeepAliveRequests">MaxKeepAliveRequests</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Number of requests allowed on a persistent
connection</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>MaxKeepAliveRequests <var>number</var></code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>MaxKeepAliveRequests 100</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code class="directive">MaxKeepAliveRequests</code> directive
    limits the number of requests allowed per connection when
    <code class="directive"><a href="#keepalive">KeepAlive</a></code> is on. If it is
    set to <code>0</code>, unlimited requests will be allowed. We
    recommend that this setting be kept to a high value for maximum
    server performance.</p>

    <p>For example:</p>

    <div class="example"><p><code>
      MaxKeepAliveRequests 500
    </code></p></div>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="maxrangeoverlaps" id="maxrangeoverlaps">Directiva</a> <a name="MaxRangeOverlaps" id="MaxRangeOverlaps">MaxRangeOverlaps</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Number of overlapping ranges (eg: <code>100-200,150-300</code>) allowed before returning the complete
        resource </td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>MaxRangeOverlaps default | unlimited | none | <var>number-of-ranges</var></code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>MaxRangeOverlaps 20</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in Apache HTTP Server 2.3.15 and later</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p></div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="maxrangereversals" id="maxrangereversals">Directiva</a> <a name="MaxRangeReversals" id="MaxRangeReversals">MaxRangeReversals</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Number of range reversals (eg: <code>100-200,50-70</code>) allowed before returning the complete
        resource </td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>MaxRangeReversals default | unlimited | none | <var>number-of-ranges</var></code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>MaxRangeReversals 20</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in Apache HTTP Server 2.3.15 and later</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p></div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="maxranges" id="maxranges">Directiva</a> <a name="MaxRanges" id="MaxRanges">MaxRanges</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Number of ranges allowed before returning the complete
resource </td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>MaxRanges default | unlimited | none | <var>number-of-ranges</var></code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>MaxRanges 200</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in Apache HTTP Server 2.3.15 and later</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p></div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="mergetrailers" id="mergetrailers">Directiva</a> <a name="MergeTrailers" id="MergeTrailers">MergeTrailers</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Determines whether trailers are merged into headers</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>MergeTrailers [on|off]</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>MergeTrailers off</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>2.4.11 and later</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p></div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="mutex" id="mutex">Directiva</a> <a name="Mutex" id="Mutex">Mutex</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Configures mutex mechanism and lock file directory for all
or specified mutexes</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>Mutex <var>mechanism</var> [default|<var>mutex-name</var>] ... [OmitPID]</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>Mutex default</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in Apache HTTP Server 2.3.4 and later</td></tr>
</table>
    <p>The <code class="directive">Mutex</code> directive sets the mechanism,
    and optionally the lock file location, that httpd and modules use
    to serialize access to resources.  Specify <code>default</code> as
    the first argument to change the settings for all mutexes; specify
    a mutex name (see table below) as the first argument to override
    defaults only for that mutex.</p>

    <p>The <code class="directive">Mutex</code> directive is typically used in
    the following exceptional situations:</p>

    <ul>
        <li>change the mutex mechanism when the default mechanism selected
        by <a class="glossarylink" href="../glossary.html#apr" title="ver glosario">APR</a> has a functional or performance
        problem</li>

        <li>change the directory used by file-based mutexes when the
        default directory does not support locking</li>
    </ul>

    <div class="note"><h3>Supported modules</h3>
    <p>This directive only configures mutexes which have been registered
    with the core server using the <code>ap_mutex_register()</code> API.
    All modules bundled with httpd support the <code class="directive">Mutex</code>
    directive, but third-party modules may not.  Consult the documentation
    of the third-party module, which must indicate the mutex name(s) which
    can be configured if this directive is supported.</p>
    </div>

    <p>The following mutex <em>mechanisms</em> are available:</p>
    <ul>
        <li><code>default | yes</code>
        <p>This selects the default locking implementation, as determined by
        <a class="glossarylink" href="../glossary.html#apr" title="ver glosario">APR</a>.  The default locking implementation can
        be displayed by running <code class="program"><a href="../programs/httpd.html">httpd</a></code> with the 
        <code>-V</code> option.</p></li>

        <li><code>none | no</code>
        <p>This effectively disables the mutex, and is only allowed for a
        mutex if the module indicates that it is a valid choice.  Consult the
        module documentation for more information.</p></li>

        <li><code>posixsem</code>
        <p>This is a mutex variant based on a Posix semaphore.</p>

        <div class="warning"><h3>Warning</h3>
        <p>The semaphore ownership is not recovered if a thread in the process
        holding the mutex segfaults, resulting in a hang of the web server.</p>
        </div>
        </li>

        <li><code>sysvsem</code>
        <p>This is a mutex variant based on a SystemV IPC semaphore.</p>

        <div class="warning"><h3>Warning</h3>
        <p>It is possible to "leak" SysV semaphores if processes crash 
        before the semaphore is removed.</p>
	</div>

        <div class="warning"><h3>Security</h3>
        <p>The semaphore API allows for a denial of service attack by any
        CGIs running under the same uid as the webserver (<em>i.e.</em>,
        all CGIs, unless you use something like <code class="program"><a href="../programs/suexec.html">suexec</a></code>
        or <code>cgiwrapper</code>).</p>
	</div>
        </li>

        <li><code>sem</code>
        <p>This selects the "best" available semaphore implementation, choosing
        between Posix and SystemV IPC semaphores, in that order.</p></li>

        <li><code>pthread</code>
        <p>This is a mutex variant based on cross-process Posix thread
        mutexes.</p>

        <div class="warning"><h3>Warning</h3>
        <p>On most systems, if a child process terminates abnormally while
        holding a mutex that uses this implementation, the server will deadlock
        and stop responding to requests.  When this occurs, the server will
        require a manual restart to recover.</p>
        <p>Solaris is a notable exception as it provides a mechanism which
        usually allows the mutex to be recovered after a child process
        terminates abnormally while holding a mutex.</p>
        <p>If your system implements the
        <code>pthread_mutexattr_setrobust_np()</code> function, you may be able
        to use the <code>pthread</code> option safely.</p>
        </div>
        </li>

        <li><code>fcntl:/path/to/mutex</code>
        <p>This is a mutex variant where a physical (lock-)file and the 
        <code>fcntl()</code> function are used as the mutex.</p>

        <div class="warning"><h3>Warning</h3>
        <p>When multiple mutexes based on this mechanism are used within
        multi-threaded, multi-process environments, deadlock errors (EDEADLK)
        can be reported for valid mutex operations if <code>fcntl()</code>
        is not thread-aware, such as on Solaris.</p>
	</div>
        </li>

        <li><code>flock:/path/to/mutex</code>
        <p>This is similar to the <code>fcntl:/path/to/mutex</code> method
        with the exception that the <code>flock()</code> function is used to
        provide file locking.</p></li>

        <li><code>file:/path/to/mutex</code>
        <p>This selects the "best" available file locking implementation,
        choosing between <code>fcntl</code> and <code>flock</code>, in that
        order.</p></li>
    </ul>

    <p>Most mechanisms are only available on selected platforms, where the 
    underlying platform and <a class="glossarylink" href="../glossary.html#apr" title="ver glosario">APR</a> support it.  Mechanisms
    which aren't available on all platforms are <em>posixsem</em>,
    <em>sysvsem</em>, <em>sem</em>, <em>pthread</em>, <em>fcntl</em>, 
    <em>flock</em>, and <em>file</em>.</p>

    <p>With the file-based mechanisms <em>fcntl</em> and <em>flock</em>,
    the path, if provided, is a directory where the lock file will be created.
    The default directory is httpd's run-time file directory relative to
    <code class="directive"><a href="#serverroot">ServerRoot</a></code>.  Always use a local disk
    filesystem for <code>/path/to/mutex</code> and never a directory residing
    on a NFS- or AFS-filesystem.  The basename of the file will be the mutex
    type, an optional instance string provided by the module, and unless the
    <code>OmitPID</code> keyword is specified, the process id of the httpd 
    parent process will be appended to to make the file name unique, avoiding
    conflicts when multiple httpd instances share a lock file directory.  For
    example, if the mutex name is <code>mpm-accept</code> and the lock file
    directory is <code>/var/httpd/locks</code>, the lock file name for the
    httpd instance with parent process id 12345 would be 
    <code>/var/httpd/locks/mpm-accept.12345</code>.</p>

    <div class="warning"><h3>Security</h3>
    <p>It is best to <em>avoid</em> putting mutex files in a world-writable
    directory such as <code>/var/tmp</code> because someone could create
    a denial of service attack and prevent the server from starting by
    creating a lockfile with the same name as the one the server will try
    to create.</p>
    </div>

    <p>The following table documents the names of mutexes used by httpd
    and bundled modules.</p>

    <table class="bordered"><tr class="header">
            <th>Mutex name</th>
            <th>Module(s)</th>
            <th>Protected resource</th>
	</tr>
<tr>
            <td><code>mpm-accept</code></td>
            <td><code class="module"><a href="../mod/prefork.html">prefork</a></code> and <code class="module"><a href="../mod/worker.html">worker</a></code> MPMs</td>
            <td>incoming connections, to avoid the thundering herd problem;
            for more information, refer to the
            <a href="../misc/perf-tuning.html">performance tuning</a>
            documentation</td>
	</tr>
<tr class="odd">
            <td><code>authdigest-client</code></td>
            <td><code class="module"><a href="../mod/mod_auth_digest.html">mod_auth_digest</a></code></td>
            <td>client list in shared memory</td>
	</tr>
<tr>
            <td><code>authdigest-opaque</code></td>
            <td><code class="module"><a href="../mod/mod_auth_digest.html">mod_auth_digest</a></code></td>
            <td>counter in shared memory</td>
	</tr>
<tr class="odd">
            <td><code>ldap-cache</code></td>
            <td><code class="module"><a href="../mod/mod_ldap.html">mod_ldap</a></code></td>
            <td>LDAP result cache</td>
	</tr>
<tr>
            <td><code>rewrite-map</code></td>
            <td><code class="module"><a href="../mod/mod_rewrite.html">mod_rewrite</a></code></td>
            <td>communication with external mapping programs, to avoid
            intermixed I/O from multiple requests</td>
	</tr>
<tr class="odd">
            <td><code>ssl-cache</code></td>
            <td><code class="module"><a href="../mod/mod_ssl.html">mod_ssl</a></code></td>
            <td>SSL session cache</td>
	</tr>
<tr>
            <td><code>ssl-stapling</code></td>
            <td><code class="module"><a href="../mod/mod_ssl.html">mod_ssl</a></code></td>
            <td>OCSP stapling response cache</td>
	</tr>
<tr class="odd">
            <td><code>watchdog-callback</code></td>
            <td><code class="module"><a href="../mod/mod_watchdog.html">mod_watchdog</a></code></td>
            <td>callback function of a particular client module</td>
	</tr>
</table>

    <p>The <code>OmitPID</code> keyword suppresses the addition of the httpd
    parent process id from the lock file name.</p>

    <p>In the following example, the mutex mechanism for the MPM accept
    mutex will be changed from the compiled-in default to <code>fcntl</code>,
    with the associated lock file created in directory
    <code>/var/httpd/locks</code>.  The mutex mechanism for all other mutexes
    will be changed from the compiled-in default to <code>sysvsem</code>.</p>

    <div class="example"><p><code>
    Mutex default sysvsem<br />
    Mutex mpm-accept fcntl:/var/httpd/locks
    </code></p></div>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="namevirtualhost" id="namevirtualhost">Directiva</a> <a name="NameVirtualHost" id="NameVirtualHost">NameVirtualHost</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Designates an IP address for name-virtual
hosting</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>NameVirtualHost <var>addr</var>[:<var>port</var>]</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>

<p>A single <code class="directive">NameVirtualHost</code> directive 
identifies a set of identical virtual hosts on which the server will  
further select from on the basis of the <em>hostname</em> 
requested by the client.  The <code class="directive">NameVirtualHost</code>
directive is a required directive if you want to configure 
<a href="../vhosts/">name-based virtual hosts</a>.</p>

<p>This directive, and the corresponding <code class="directive">VirtualHost</code>,
<em>must</em> be qualified with a port number if the server supports both HTTP 
and HTTPS connections.</p>

<p>Although <var>addr</var> can be a hostname, it is recommended
that you always use an IP address or a wildcard.  A wildcard
NameVirtualHost matches only virtualhosts that also have a literal wildcard
as their argument.</p>

<p>In cases where a firewall or other proxy receives the requests and 
forwards them on a different IP address to the server, you must specify the
IP address of the physical interface on the machine which will be
servicing the requests. </p>

<p> In the example below, requests received on interface 192.0.2.1 and port 80 
will only select among the first two virtual hosts. Requests received on
port 80 on any other interface will only select among the third and fourth
virtual hosts. In the common case where the interface isn't important 
to the mapping, only the "*:80" NameVirtualHost and VirtualHost directives 
are necessary.</p>

   <div class="example"><p><code>
      NameVirtualHost 192.0.2.1:80<br />
      NameVirtualHost *:80<br /><br />

      &lt;VirtualHost 192.0.2.1:80&gt;<br />
      &nbsp; ServerName namebased-a.example.com<br />
      &lt;/VirtualHost&gt;<br />
      <br />
      &lt;VirtualHost 192.0.2.1:80&gt;<br />
      &nbsp; Servername namebased-b.example.com<br />
      &lt;/VirtualHost&gt;<br />
      <br />
      &lt;VirtualHost *:80&gt;<br />
      &nbsp; ServerName namebased-c.example.com <br />
      &lt;/VirtualHost&gt;<br />
      <br />
      &lt;VirtualHost *:80&gt;<br />
      &nbsp; ServerName namebased-d.example.com <br />
      &lt;/VirtualHost&gt;<br />
      <br />

    </code></p></div>

    <p>If no matching virtual host is found, then the first listed
    virtual host that matches the IP address and port will be used.</p>


    <p>IPv6 addresses must be enclosed in square brackets, as shown
    in the following example:</p>

    <div class="example"><p><code>
      NameVirtualHost [2001:db8::a00:20ff:fea7:ccea]:8080
    </code></p></div>

    <div class="note"><h3>Argument to <code class="directive">&lt;VirtualHost&gt;</code>
      directive</h3>
      <p>Note that the argument to the <code class="directive">&lt;VirtualHost&gt;</code> directive must
      exactly match the argument to the <code class="directive">NameVirtualHost</code> directive.</p>

      <div class="example"><p><code>
        NameVirtualHost 192.0.2.2:80<br />
        &lt;VirtualHost 192.0.2.2:80&gt;<br />
        # ...<br />
        &lt;/VirtualHost&gt;<br />
      </code></p></div>
    </div>

<h3>Consulte también</h3>
<ul>
<li><a href="../vhosts/">Virtual Hosts
documentation</a></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="options" id="options">Directiva</a> <a name="Options" id="Options">Options</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Configures what features are available in a particular
directory</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>Options
    [+|-]<var>option</var> [[+|-]<var>option</var>] ...</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>Options All</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>Options</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code class="directive">Options</code> directive controls which
    server features are available in a particular directory.</p>

    <p><var>option</var> can be set to <code>None</code>, in which
    case none of the extra features are enabled, or one or more of
    the following:</p>

    <dl>
      <dt><code>All</code></dt>

      <dd>All options except for <code>MultiViews</code>. This is the default
      setting.</dd>

      <dt><code>ExecCGI</code></dt>

      <dd>
      Execution of CGI scripts using <code class="module"><a href="../mod/mod_cgi.html">mod_cgi</a></code>
      is permitted.</dd>

      <dt><code>FollowSymLinks</code></dt>

      <dd>

      The server will follow symbolic links in this directory.
      <div class="note">
      <p>Even though the server follows the symlink it does <em>not</em>
      change the pathname used to match against <code class="directive"><a href="#directory">&lt;Directory&gt;</a></code> sections.</p>
      <p>Note also, that this option <strong>gets ignored</strong> if set
      inside a <code class="directive"><a href="#location">&lt;Location&gt;</a></code>
      section.</p>
      <p>Omitting this option should not be considered a security restriction,
      since symlink testing is subject to race conditions that make it
      circumventable.</p>
      </div></dd>

      <dt><code>Includes</code></dt>

      <dd>
      Server-side includes provided by <code class="module"><a href="../mod/mod_include.html">mod_include</a></code>
      are permitted.</dd>

      <dt><code>IncludesNOEXEC</code></dt>

      <dd>

      Server-side includes are permitted, but the <code>#exec
      cmd</code> and <code>#exec cgi</code> are disabled. It is still
      possible to <code>#include virtual</code> CGI scripts from
      <code class="directive"><a href="../mod/mod_alias.html#scriptalias">ScriptAlias</a></code>ed
      directories.</dd>

      <dt><code>Indexes</code></dt>

      <dd>
      If a URL which maps to a directory is requested, and there
      is no <code class="directive"><a href="../mod/mod_dir.html#directoryindex">DirectoryIndex</a></code>
      (<em>e.g.</em>, <code>index.html</code>) in that directory, then
      <code class="module"><a href="../mod/mod_autoindex.html">mod_autoindex</a></code> will return a formatted listing
      of the directory.</dd>

      <dt><code>MultiViews</code></dt>

      <dd>
      <a href="../content-negotiation.html">Content negotiated</a>
      "MultiViews" are allowed using
      <code class="module"><a href="../mod/mod_negotiation.html">mod_negotiation</a></code>.
      <div class="note"><h3>Note</h3> <p>This option gets ignored if set
      anywhere other than <code class="directive"><a href="#directory">&lt;Directory&gt;</a></code>, as <code class="module"><a href="../mod/mod_negotiation.html">mod_negotiation</a></code>
      needs real resources to compare against and evaluate from.</p></div>
      </dd>

      <dt><code>SymLinksIfOwnerMatch</code></dt>

      <dd>The server will only follow symbolic links for which the
      target file or directory is owned by the same user id as the
      link.

      <div class="note"><h3>Note</h3> <p>This option gets ignored if
      set inside a <code class="directive"><a href="#location">&lt;Location&gt;</a></code> section.</p>
      <p>This option should not be considered a security restriction,
      since symlink testing is subject to race conditions that make it
      circumventable.</p></div>
      </dd>
    </dl>

    <p>Normally, if multiple <code class="directive">Options</code> could
    apply to a directory, then the most specific one is used and
    others are ignored; the options are not merged. (See <a href="../sections.html#mergin">how sections are merged</a>.)
    However if <em>all</em> the options on the
    <code class="directive">Options</code> directive are preceded by a
    <code>+</code> or <code>-</code> symbol, the options are
    merged. Any options preceded by a <code>+</code> are added to the
    options currently in force, and any options preceded by a
    <code>-</code> are removed from the options currently in
    force. </p>

    <div class="warning"><h3>Warning</h3>
    <p>Mixing <code class="directive">Options</code> with a <code>+</code> or
    <code>-</code> with those without is not valid syntax, and is likely
    to cause unexpected results.</p>
    </div>

    <p>For example, without any <code>+</code> and <code>-</code> symbols:</p>

    <div class="example"><p><code>
      &lt;Directory /web/docs&gt;<br />
      <span class="indent">
        Options Indexes FollowSymLinks<br />
      </span>
      &lt;/Directory&gt;<br />
      <br />
      &lt;Directory /web/docs/spec&gt;<br />
      <span class="indent">
        Options Includes<br />
      </span>
      &lt;/Directory&gt;
    </code></p></div>

    <p>then only <code>Includes</code> will be set for the
    <code>/web/docs/spec</code> directory. However if the second
    <code class="directive">Options</code> directive uses the <code>+</code> and
    <code>-</code> symbols:</p>

    <div class="example"><p><code>
      &lt;Directory /web/docs&gt;<br />
      <span class="indent">
        Options Indexes FollowSymLinks<br />
      </span>
      &lt;/Directory&gt;<br />
      <br />
      &lt;Directory /web/docs/spec&gt;<br />
      <span class="indent">
        Options +Includes -Indexes<br />
      </span>
      &lt;/Directory&gt;
    </code></p></div>

    <p>then the options <code>FollowSymLinks</code> and
    <code>Includes</code> are set for the <code>/web/docs/spec</code>
    directory.</p>

    <div class="note"><h3>Note</h3>
      <p>Using <code>-IncludesNOEXEC</code> or
      <code>-Includes</code> disables server-side includes completely
      regardless of the previous setting.</p>
    </div>

    <p>The default in the absence of any other settings is
    <code>All</code>.</p>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="protocol" id="protocol">Directiva</a> <a name="Protocol" id="Protocol">Protocol</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Protocol for a listening socket</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>Protocol <var>protocol</var></code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in Apache 2.1.5 and later.
On Windows from Apache 2.3.3 and later.</td></tr>
</table>
    <p>This directive specifies the protocol used for a specific listening socket.
       The protocol is used to determine which module should handle a request, and
       to apply protocol specific optimizations with the <code class="directive">AcceptFilter</code>
       directive.</p>

    <p>You only need to set the protocol if you are running on non-standard ports, otherwise <code>http</code> is assumed for port 80 and <code>https</code> for port 443.</p>

    <p>For example, if you are running <code>https</code> on a non-standard port, specify the protocol explicitly:</p>

    <div class="example"><p><code>
      Protocol https
    </code></p></div>

    <p>You can also specify the protocol using the <code class="directive"><a href="../mod/mpm_common.html#listen">Listen</a></code> directive.</p>

<h3>Consulte también</h3>
<ul>
<li><code class="directive">AcceptFilter</code></li>
<li><code class="directive"><a href="../mod/mpm_common.html#listen">Listen</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="protocols" id="protocols">Directiva</a> <a name="Protocols" id="Protocols">Protocols</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Protocols available for a server/virtual host</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>Protocols <var>protocol</var> ...</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>Protocols http/1.1</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Only available from Apache 2.4.17 and later.</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p><h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#protocolshonororder">ProtocolsHonorOrder</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="protocolshonororder" id="protocolshonororder">Directiva</a> <a name="ProtocolsHonorOrder" id="ProtocolsHonorOrder">ProtocolsHonorOrder</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Determines if order of Protocols determines precedence during negotiation</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>ProtocolsHonorOrder On|Off</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>ProtocolsHonorOrder On</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Only available from Apache 2.4.17 and later.</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p><h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#protocols">Protocols</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="qualifyredirecturl" id="qualifyredirecturl">Directiva</a> <a name="QualifyRedirectURL" id="QualifyRedirectURL">QualifyRedirectURL</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Controls whether the REDIRECT_URL environment variable is
             fully qualified</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>QualifyRedirectURL ON|OFF</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>QualifyRedirectURL OFF</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>FileInfo</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Directive supported in 2.4.18 and later. 2.4.17 acted
as if 'QualifyRedirectURL ON' was configured.</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p></div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="regexdefaultoptions" id="regexdefaultoptions">Directiva</a> <a name="RegexDefaultOptions" id="RegexDefaultOptions">RegexDefaultOptions</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Allow to configure global/default options for regexes</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>RegexDefaultOptions [none] [+|-]<var>option</var> [[+|-]<var>option</var>] ...</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>RegexDefaultOptions DOLLAR_ENDONLY</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Only available from Apache 2.4.30 and later.</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p></div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="registerhttpmethod" id="registerhttpmethod">Directiva</a> <a name="RegisterHttpMethod" id="RegisterHttpMethod">RegisterHttpMethod</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Register non-standard HTTP methods</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>RegisterHttpMethod <var>method</var> [<var>method</var> [...]]</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in Apache HTTP Server 2.4.24 and later</td></tr>
</table><p>The documentation for this directive has
            not been translated yet. Please have a look at the English
            version.</p><h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#httpprotocoloptions">HTTPProtocolOptions</a></code></li>
<li><code class="directive"><a href="../mod/mod_allowmethods.html#allowmethods">AllowMethods</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="rlimitcpu" id="rlimitcpu">Directiva</a> <a name="RLimitCPU" id="RLimitCPU">RLimitCPU</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Limits the CPU consumption of processes launched
by Apache httpd children</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>RLimitCPU <var>seconds</var>|max [<var>seconds</var>|max]</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>Unset; uses operating system defaults</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>All</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>Takes 1 or 2 parameters. The first parameter sets the soft
    resource limit for all processes and the second parameter sets
    the maximum resource limit. Either parameter can be a number,
    or <code>max</code> to indicate to the server that the limit should
    be set to the maximum allowed by the operating system
    configuration. Raising the maximum resource limit requires that
    the server is running as <code>root</code>, or in the initial startup
    phase.</p>

    <p>This applies to processes forked off from Apache httpd children
    servicing requests, not the Apache httpd children themselves. This
    includes CGI scripts and SSI exec commands, but not any
    processes forked off from the Apache httpd parent such as piped
    logs.</p>

    <p>CPU resource limits are expressed in seconds per
    process.</p>

<h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#rlimitmem">RLimitMEM</a></code></li>
<li><code class="directive"><a href="#rlimitnproc">RLimitNPROC</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="rlimitmem" id="rlimitmem">Directiva</a> <a name="RLimitMEM" id="RLimitMEM">RLimitMEM</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Limits the memory consumption of processes launched
by Apache httpd children</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>RLimitMEM <var>bytes</var>|max [<var>bytes</var>|max]</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>Unset; uses operating system defaults</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>All</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>Takes 1 or 2 parameters. The first parameter sets the soft
    resource limit for all processes and the second parameter sets
    the maximum resource limit. Either parameter can be a number,
    or <code>max</code> to indicate to the server that the limit should
    be set to the maximum allowed by the operating system
    configuration. Raising the maximum resource limit requires that
    the server is running as <code>root</code>, or in the initial startup
    phase.</p>

    <p>This applies to processes forked off from Apache httpd children
    servicing requests, not the Apache httpd children themselves. This
    includes CGI scripts and SSI exec commands, but not any
    processes forked off from the Apache httpd parent such as piped
    logs.</p>

    <p>Memory resource limits are expressed in bytes per
    process.</p>

<h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#rlimitcpu">RLimitCPU</a></code></li>
<li><code class="directive"><a href="#rlimitnproc">RLimitNPROC</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="rlimitnproc" id="rlimitnproc">Directiva</a> <a name="RLimitNPROC" id="RLimitNPROC">RLimitNPROC</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Limits the number of processes that can be launched by
processes launched by Apache httpd children</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>RLimitNPROC <var>number</var>|max [<var>number</var>|max]</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>Unset; uses operating system defaults</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>All</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>Takes 1 or 2 parameters. The first parameter sets the soft
    resource limit for all processes and the second parameter sets
    the maximum resource limit. Either parameter can be a number,
    or <code>max</code> to indicate to the server that the limit
    should be set to the maximum allowed by the operating system
    configuration. Raising the maximum resource limit requires that
    the server is running as <code>root</code>, or in the initial startup
    phase.</p>

    <p>This applies to processes forked off from Apache httpd children
    servicing requests, not the Apache httpd children themselves. This
    includes CGI scripts and SSI exec commands, but not any
    processes forked off from the Apache httpd parent such as piped
    logs.</p>

    <p>Process limits control the number of processes per user.</p>

    <div class="note"><h3>Note</h3>
      <p>If CGI processes are <strong>not</strong> running
      under user ids other than the web server user id, this directive
      will limit the number of processes that the server itself can
      create. Evidence of this situation will be indicated by
      <strong><code>cannot fork</code></strong> messages in the
      <code>error_log</code>.</p>
    </div>

<h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#rlimitmem">RLimitMEM</a></code></li>
<li><code class="directive"><a href="#rlimitcpu">RLimitCPU</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="scriptinterpretersource" id="scriptinterpretersource">Directiva</a> <a name="ScriptInterpreterSource" id="ScriptInterpreterSource">ScriptInterpreterSource</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Technique for locating the interpreter for CGI
scripts</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>ScriptInterpreterSource Registry|Registry-Strict|Script</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>ScriptInterpreterSource Script</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>FileInfo</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Win32 only;
option <code>Registry-Strict</code> is available in Apache HTTP Server 2.0 and
later</td></tr>
</table>
    <p>This directive is used to control how Apache httpd finds the
    interpreter used to run CGI scripts. The default setting is
    <code>Script</code>. This causes Apache httpd to use the interpreter pointed to
    by the shebang line (first line, starting with <code>#!</code>) in the
    script. On Win32 systems this line usually looks like:</p>

    <div class="example"><p><code>
      #!C:/Perl/bin/perl.exe
    </code></p></div>

    <p>or, if <code>perl</code> is in the <code>PATH</code>, simply:</p>

    <div class="example"><p><code>
      #!perl
    </code></p></div>

    <p>Setting <code>ScriptInterpreterSource Registry</code> will
    cause the Windows Registry tree <code>HKEY_CLASSES_ROOT</code> to be
    searched using the script file extension (e.g., <code>.pl</code>) as a
    search key. The command defined by the registry subkey
    <code>Shell\ExecCGI\Command</code> or, if it does not exist, by the subkey
    <code>Shell\Open\Command</code> is used to open the script file. If the
    registry keys cannot be found, Apache httpd falls back to the behavior of the
    <code>Script</code> option.</p>

    <div class="warning"><h3>Security</h3>
    <p>Be careful when using <code>ScriptInterpreterSource
    Registry</code> with <code class="directive"><a href="../mod/mod_alias.html#scriptalias">ScriptAlias</a></code>'ed directories, because
    Apache httpd will try to execute <strong>every</strong> file within this
    directory. The <code>Registry</code> setting may cause undesired
    program calls on files which are typically not executed. For
    example, the default open command on <code>.htm</code> files on
    most Windows systems will execute Microsoft Internet Explorer, so
    any HTTP request for an <code>.htm</code> file existing within the
    script directory would start the browser in the background on the
    server. This is a good way to crash your system within a minute or
    so.</p>
    </div>

    <p>The option <code>Registry-Strict</code> which is new in Apache HTTP Server
    2.0 does the same thing as <code>Registry</code> but uses only the
    subkey <code>Shell\ExecCGI\Command</code>. The
    <code>ExecCGI</code> key is not a common one. It must be
    configured manually in the windows registry and hence prevents
    accidental program calls on your system.</p>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="seerequesttail" id="seerequesttail">Directiva</a> <a name="SeeRequestTail" id="SeeRequestTail">SeeRequestTail</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Determine if mod_status displays the first 63 characters
of a request or the last 63, assuming the request itself is greater than
63 chars.</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>SeeRequestTail On|Off</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>SeeRequestTail Off</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in Apache httpd 2.2.7 and later.</td></tr>
</table>
    <p>mod_status with <code>ExtendedStatus On</code>
    displays the actual request being handled. 
    For historical purposes, only 63 characters of the request
    are actually stored for display purposes. This directive
    controls whether the 1st 63 characters are stored (the previous
    behavior and the default) or if the last 63 characters are. This
    is only applicable, of course, if the length of the request is
    64 characters or greater.</p>

    <p>If Apache httpd is handling <code>GET&nbsp;/disk1/storage/apache/htdocs/images/imagestore1/food/apples.jpg&nbsp;HTTP/1.1</code> mod_status displays as follows:
    </p>

    <table class="bordered">
      <tr>
        <th>Off (default)</th>
        <td>GET&nbsp;/disk1/storage/apache/htdocs/images/imagestore1/food/apples</td>
      </tr>
      <tr>
        <th>On</th>
        <td>orage/apache/htdocs/images/imagestore1/food/apples.jpg&nbsp;HTTP/1.1</td>
      </tr>
    </table>


</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="serveradmin" id="serveradmin">Directiva</a> <a name="ServerAdmin" id="ServerAdmin">ServerAdmin</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Email address that the server includes in error
messages sent to the client</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>ServerAdmin <var>email-address</var>|<var>URL</var></code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code class="directive">ServerAdmin</code> sets the contact address
    that the server includes in any error messages it returns to the
    client. If the <code>httpd</code> doesn't recognize the supplied argument
    as an URL, it
    assumes, that it's an <var>email-address</var> and prepends it with
    <code>mailto:</code> in hyperlink targets. However, it's recommended to
    actually use an email address, since there are a lot of CGI scripts that
    make that assumption. If you want to use an URL, it should point to another
    server under your control. Otherwise users may not be able to contact you in
    case of errors.</p>

    <p>It may be worth setting up a dedicated address for this, e.g.</p>

    <div class="example"><p><code>
      ServerAdmin www-admin@foo.example.com
    </code></p></div>
    <p>as users do not always mention that they are talking about the
    server!</p>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="serveralias" id="serveralias">Directiva</a> <a name="ServerAlias" id="ServerAlias">ServerAlias</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Alternate names for a host used when matching requests
to name-virtual hosts</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>ServerAlias <var>hostname</var> [<var>hostname</var>] ...</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code class="directive">ServerAlias</code> directive sets the
    alternate names for a host, for use with <a href="../vhosts/name-based.html">name-based virtual hosts</a>. The
    <code class="directive">ServerAlias</code> may include wildcards, if appropriate.</p>

    <div class="example"><p><code>
      &lt;VirtualHost *:80&gt;<br />
      ServerName server.domain.com<br />
      ServerAlias server server2.domain.com server2<br />
      ServerAlias *.example.com<br />
      UseCanonicalName Off<br />
      # ...<br />
      &lt;/VirtualHost&gt;
    </code></p></div>

<h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#usecanonicalname">UseCanonicalName</a></code></li>
<li><a href="../vhosts/">Apache HTTP Server Virtual Host documentation</a></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="servername" id="servername">Directiva</a> <a name="ServerName" id="ServerName">ServerName</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Hostname and port that the server uses to identify
itself</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>ServerName [<var>scheme</var>://]<var>fully-qualified-domain-name</var>[:<var>port</var>]</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code class="directive">ServerName</code> directive sets the
    request scheme, hostname and
    port that the server uses to identify itself.  This is used when
    creating redirection URLs.</p>

    <p>Additionally, <code class="directive">ServerName</code> is used (possibly
    in conjunction with <code class="directive">ServerAlias</code>) to uniquely
    identify a virtual host, when using <a href="../vhosts/name-based.html">name-based virtual hosts</a>.</p>
    
    <p>For example, if the name of the
    machine hosting the web server is <code>simple.example.com</code>,
    but the machine also has the DNS alias <code>www.example.com</code>
    and you wish the web server to be so identified, the following
    directive should be used:</p>

    <div class="example"><p><code>
      ServerName www.example.com:80
    </code></p></div>

    <p>The <code class="directive">ServerName</code> directive
    may appear anywhere within the definition of a server. However,
    each appearance overrides the previous appearance (within that
    server).</p>

    <p>If no <code class="directive">ServerName</code> is specified, then the
    server attempts to deduce the hostname by performing a reverse
    lookup on the IP address. If no port is specified in the
    <code class="directive">ServerName</code>, then the server will use the
    port from the incoming request. For optimal reliability and
    predictability, you should specify an explicit hostname and port
    using the <code class="directive">ServerName</code> directive.</p>

    <p>If you are using <a href="../vhosts/name-based.html">name-based virtual hosts</a>,
    the <code class="directive">ServerName</code> inside a
    <code class="directive"><a href="#virtualhost">&lt;VirtualHost&gt;</a></code>
    section specifies what hostname must appear in the request's
    <code>Host:</code> header to match this virtual host.</p>

    <p>Sometimes, the server runs behind a device that processes SSL,
    such as a reverse proxy, load balancer or SSL offload
    appliance. When this is the case, specify the
    <code>https://</code> scheme and the port number to which the
    clients connect in the <code class="directive">ServerName</code> directive
    to make sure that the server generates the correct
    self-referential URLs. 
    </p>

    <p>See the description of the
    <code class="directive"><a href="#usecanonicalname">UseCanonicalName</a></code> and
    <code class="directive"><a href="#usecanonicalphysicalport">UseCanonicalPhysicalPort</a></code> directives for
    settings which determine whether self-referential URLs (e.g., by the
    <code class="module"><a href="../mod/mod_dir.html">mod_dir</a></code> module) will refer to the
    specified port, or to the port number given in the client's request.
    </p>

    <div class="warning">
    <p>Failure to set <code class="directive">ServerName</code> to a name that
    your server can resolve to an IP address will result in a startup
    warning. <code>httpd</code> will then use whatever hostname it can
    determine, using the system's <code>hostname</code> command. This
    will almost never be the hostname you actually want.</p>
    <div class="example"><p><code>
    httpd: Could not reliably determine the server's fully qualified domain name, using rocinante.local for ServerName
    </code></p></div>
    </div>


<h3>Consulte también</h3>
<ul>
<li><a href="../dns-caveats.html">Issues Regarding DNS and
    Apache HTTP Server</a></li>
<li><a href="../vhosts/">Apache HTTP Server virtual host
    documentation</a></li>
<li><code class="directive"><a href="#usecanonicalname">UseCanonicalName</a></code></li>
<li><code class="directive"><a href="#usecanonicalphysicalport">UseCanonicalPhysicalPort</a></code></li>
<li><code class="directive"><a href="#namevirtualhost">NameVirtualHost</a></code></li>
<li><code class="directive"><a href="#serveralias">ServerAlias</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="serverpath" id="serverpath">Directiva</a> <a name="ServerPath" id="ServerPath">ServerPath</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Legacy URL pathname for a name-based virtual host that
is accessed by an incompatible browser</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>ServerPath <var>URL-path</var></code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code class="directive">ServerPath</code> directive sets the legacy
    URL pathname for a host, for use with <a href="../vhosts/">name-based virtual hosts</a>.</p>

<h3>Consulte también</h3>
<ul>
<li><a href="../vhosts/">Apache HTTP Server Virtual Host documentation</a></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="serverroot" id="serverroot">Directiva</a> <a name="ServerRoot" id="ServerRoot">ServerRoot</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Base directory for the server installation</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>ServerRoot <var>directory-path</var></code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>ServerRoot /usr/local/apache</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code class="directive">ServerRoot</code> directive sets the
    directory in which the server lives. Typically it will contain the
    subdirectories <code>conf/</code> and <code>logs/</code>. Relative
    paths in other configuration directives (such as <code class="directive"><a href="#include">Include</a></code> or <code class="directive"><a href="../mod/mod_so.html#loadmodule">LoadModule</a></code>, for example) are taken as 
    relative to this directory.</p>

    <div class="example"><h3>Example</h3><p><code>
      ServerRoot /home/httpd
    </code></p></div>


<h3>Consulte también</h3>
<ul>
<li><a href="../invoking.html">the <code>-d</code>
    option to <code>httpd</code></a></li>
<li><a href="../misc/security_tips.html#serverroot">the
    security tips</a> for information on how to properly set
    permissions on the <code class="directive">ServerRoot</code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="serversignature" id="serversignature">Directiva</a> <a name="ServerSignature" id="ServerSignature">ServerSignature</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Configures the footer on server-generated documents</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>ServerSignature On|Off|EMail</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>ServerSignature Off</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>All</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code class="directive">ServerSignature</code> directive allows the
    configuration of a trailing footer line under server-generated
    documents (error messages, <code class="module"><a href="../mod/mod_proxy.html">mod_proxy</a></code> ftp directory
    listings, <code class="module"><a href="../mod/mod_info.html">mod_info</a></code> output, ...). The reason why you
    would want to enable such a footer line is that in a chain of proxies,
    the user often has no possibility to tell which of the chained servers
    actually produced a returned error message.</p>

    <p>The <code>Off</code>
    setting, which is the default, suppresses the footer line (and is
    therefore compatible with the behavior of Apache-1.2 and
    below). The <code>On</code> setting simply adds a line with the
    server version number and <code class="directive"><a href="#servername">ServerName</a></code> of the serving virtual host,
    and the <code>EMail</code> setting additionally creates a
    "mailto:" reference to the <code class="directive"><a href="#serveradmin">ServerAdmin</a></code> of the referenced
    document.</p>

    <p>After version 2.0.44, the details of the server version number
    presented are controlled by the <code class="directive"><a href="#servertokens">ServerTokens</a></code> directive.</p>

<h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#servertokens">ServerTokens</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="servertokens" id="servertokens">Directiva</a> <a name="ServerTokens" id="ServerTokens">ServerTokens</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Configures the <code>Server</code> HTTP response
header</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>ServerTokens Major|Minor|Min[imal]|Prod[uctOnly]|OS|Full</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>ServerTokens Full</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>This directive controls whether <code>Server</code> response
    header field which is sent back to clients includes a
    description of the generic OS-type of the server as well as
    information about compiled-in modules.</p>

    <dl>
      <dt><code>ServerTokens Full</code> (or not specified)</dt>

      <dd>Server sends (<em>e.g.</em>): <code>Server: Apache/2.4.1
      (Unix) PHP/4.2.2 MyMod/1.2</code></dd>

      <dt><code>ServerTokens Prod[uctOnly]</code></dt>

      <dd>Server sends (<em>e.g.</em>): <code>Server:
      Apache</code></dd>

      <dt><code>ServerTokens Major</code></dt>

      <dd>Server sends (<em>e.g.</em>): <code>Server:
      Apache/2</code></dd>

      <dt><code>ServerTokens Minor</code></dt>

      <dd>Server sends (<em>e.g.</em>): <code>Server:
      Apache/2.4</code></dd>

      <dt><code>ServerTokens Min[imal]</code></dt>

      <dd>Server sends (<em>e.g.</em>): <code>Server:
      Apache/2.4.1</code></dd>

      <dt><code>ServerTokens OS</code></dt>

      <dd>Server sends (<em>e.g.</em>): <code>Server: Apache/2.4.1
      (Unix)</code></dd>

    </dl>

    <p>This setting applies to the entire server, and cannot be
    enabled or disabled on a virtualhost-by-virtualhost basis.</p>

    <p>After version 2.0.44, this directive also controls the
    information presented by the <code class="directive"><a href="#serversignature">ServerSignature</a></code> directive.</p>
    
    <div class="note">Setting <code class="directive">ServerTokens</code> to less than
    <code>minimal</code> is not recommended because it makes it more
    difficult to debug interoperational problems. Also note that
    disabling the Server: header does nothing at all to make your
    server more secure; the idea of "security through obscurity"
    is a myth and leads to a false sense of safety.</div>


<h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#serversignature">ServerSignature</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="sethandler" id="sethandler">Directiva</a> <a name="SetHandler" id="SetHandler">SetHandler</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Forces all matching files to be processed by a
handler</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>SetHandler <var>handler-name</var>|None</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>FileInfo</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Moved into the core in Apache httpd 2.0</td></tr>
</table>
    <p>When placed into an <code>.htaccess</code> file or a
    <code class="directive"><a href="#directory">&lt;Directory&gt;</a></code> or
    <code class="directive"><a href="#location">&lt;Location&gt;</a></code>
    section, this directive forces all matching files to be parsed
    through the <a href="../handler.html">handler</a> given by
    <var>handler-name</var>. For example, if you had a directory you
    wanted to be parsed entirely as imagemap rule files, regardless
    of extension, you might put the following into an
    <code>.htaccess</code> file in that directory:</p>

    <div class="example"><p><code>
      SetHandler imap-file
    </code></p></div>

    <p>Another example: if you wanted to have the server display a
    status report whenever a URL of
    <code>http://servername/status</code> was called, you might put
    the following into <code>httpd.conf</code>:</p>

    <div class="example"><p><code>
      &lt;Location /status&gt;<br />
      <span class="indent">
        SetHandler server-status<br />
      </span>
      &lt;/Location&gt;
    </code></p></div>

    <p>You can override an earlier defined <code class="directive">SetHandler</code>
    directive by using the value <code>None</code>.</p>
    <p><strong>Note:</strong> because SetHandler overrides default handlers,
    normal behaviour such as handling of URLs ending in a slash (/) as
    directories or index files is suppressed.</p>

<h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="../mod/mod_mime.html#addhandler">AddHandler</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="setinputfilter" id="setinputfilter">Directiva</a> <a name="SetInputFilter" id="SetInputFilter">SetInputFilter</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Sets the filters that will process client requests and POST
input</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>SetInputFilter <var>filter</var>[;<var>filter</var>...]</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>FileInfo</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code class="directive">SetInputFilter</code> directive sets the
    filter or filters which will process client requests and POST
    input when they are received by the server. This is in addition to
    any filters defined elsewhere, including the
    <code class="directive"><a href="../mod/mod_mime.html#addinputfilter">AddInputFilter</a></code>
    directive.</p>

    <p>If more than one filter is specified, they must be separated
    by semicolons in the order in which they should process the
    content.</p>

<h3>Consulte también</h3>
<ul>
<li><a href="../filter.html">Filters</a> documentation</li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="setoutputfilter" id="setoutputfilter">Directiva</a> <a name="SetOutputFilter" id="SetOutputFilter">SetOutputFilter</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Sets the filters that will process responses from the
server</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>SetOutputFilter <var>filter</var>[;<var>filter</var>...]</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory, .htaccess</td></tr>
<tr><th><a href="directive-dict.html#Override">Anula:</a></th><td>FileInfo</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code class="directive">SetOutputFilter</code> directive sets the filters
    which will process responses from the server before they are
    sent to the client. This is in addition to any filters defined
    elsewhere, including the
    <code class="directive"><a href="../mod/mod_mime.html#addoutputfilter">AddOutputFilter</a></code>
    directive.</p>

    <p>For example, the following configuration will process all files
    in the <code>/www/data/</code> directory for server-side
    includes.</p>

    <div class="example"><p><code>
      &lt;Directory /www/data/&gt;<br />
      <span class="indent">
        SetOutputFilter INCLUDES<br />
      </span>
      &lt;/Directory&gt;
    </code></p></div>

    <p>If more than one filter is specified, they must be separated
    by semicolons in the order in which they should process the
    content.</p>

<h3>Consulte también</h3>
<ul>
<li><a href="../filter.html">Filters</a> documentation</li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="timeout" id="timeout">Directiva</a> <a name="TimeOut" id="TimeOut">TimeOut</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Amount of time the server will wait for
certain events before failing a request</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>TimeOut <var>seconds</var></code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>TimeOut 60</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>The <code class="directive">TimeOut</code> directive defines the length
    of time Apache httpd will wait for I/O in various circumstances:</p>

    <ol>
      <li>When reading data from the client, the length of time to
      wait for a TCP packet to arrive if the read buffer is
      empty.</li>

      <li>When writing data to the client, the length of time to wait
      for an acknowledgement of a packet if the send buffer is
      full.</li>

      <li>In <code class="module"><a href="../mod/mod_cgi.html">mod_cgi</a></code>, the length of time to wait for
      output from a CGI script.</li>

      <li>In <code class="module"><a href="../mod/mod_ext_filter.html">mod_ext_filter</a></code>, the length of time to
      wait for output from a filtering process.</li>

      <li>In <code class="module"><a href="../mod/mod_proxy.html">mod_proxy</a></code>, the default timeout value if
      <code class="directive"><a href="../mod/mod_proxy.html#proxytimeout">ProxyTimeout</a></code> is not
      configured.</li>
    </ol>


</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="traceenable" id="traceenable">Directiva</a> <a name="TraceEnable" id="TraceEnable">TraceEnable</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Determines the behaviour on <code>TRACE</code> requests</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>TraceEnable <var>[on|off|extended]</var></code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>TraceEnable on</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
<tr><th><a href="directive-dict.html#Compatibility">Compatibilidad:</a></th><td>Available in Apache HTTP Server 1.3.34, 2.0.55 and later</td></tr>
</table>
    <p>This directive overrides the behavior of <code>TRACE</code> for both
    the core server and <code class="module"><a href="../mod/mod_proxy.html">mod_proxy</a></code>.  The default
    <code>TraceEnable on</code> permits <code>TRACE</code> requests per
    RFC 2616, which disallows any request body to accompany the request.
    <code>TraceEnable off</code> causes the core server and
    <code class="module"><a href="../mod/mod_proxy.html">mod_proxy</a></code> to return a <code>405</code> (Method not
    allowed) error to the client.</p>

    <p>Finally, for testing and diagnostic purposes only, request
    bodies may be allowed using the non-compliant <code>TraceEnable 
    extended</code> directive.  The core (as an origin server) will
    restrict the request body to 64k (plus 8k for chunk headers if
    <code>Transfer-Encoding: chunked</code> is used).  The core will
    reflect the full headers and all chunk headers with the response
    body.  As a proxy server, the request body is not restricted to 64k.</p>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="undefine" id="undefine">Directiva</a> <a name="UnDefine" id="UnDefine">UnDefine</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Undefine the existence of a variable</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>UnDefine <var>parameter-name</var></code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>Undoes the effect of a <code class="directive"><a href="#define">Define</a></code> or
    of passing a <code>-D</code> argument to <code class="program"><a href="../programs/httpd.html">httpd</a></code>.</p>
    <p>This directive can be used to toggle the use of <code class="directive"><a href="#ifdefine">&lt;IfDefine&gt;</a></code> sections without needing to alter
    <code>-D</code> arguments in any startup scripts.</p>

</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="usecanonicalname" id="usecanonicalname">Directiva</a> <a name="UseCanonicalName" id="UseCanonicalName">UseCanonicalName</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Configures how the server determines its own name and
port</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>UseCanonicalName On|Off|DNS</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>UseCanonicalName Off</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>In many situations Apache httpd must construct a <em>self-referential</em>
    URL -- that is, a URL that refers back to the same server. With
    <code>UseCanonicalName On</code> Apache httpd will use the hostname and port
    specified in the <code class="directive"><a href="#servername">ServerName</a></code>
    directive to construct the canonical name for the server. This name
    is used in all self-referential URLs, and for the values of
    <code>SERVER_NAME</code> and <code>SERVER_PORT</code> in CGIs.</p>

    <p>With <code>UseCanonicalName Off</code> Apache httpd will form
    self-referential URLs using the hostname and port supplied by
    the client if any are supplied (otherwise it will use the
    canonical name, as defined above). These values are the same
    that are used to implement <a href="../vhosts/name-based.html">name-based virtual hosts</a>,
    and are available with the same clients. The CGI variables
    <code>SERVER_NAME</code> and <code>SERVER_PORT</code> will be
    constructed from the client supplied values as well.</p>

    <p>An example where this may be useful is on an intranet server
    where you have users connecting to the machine using short
    names such as <code>www</code>. You'll notice that if the users
    type a shortname, and a URL which is a directory, such as
    <code>http://www/splat</code>, <em>without the trailing
    slash</em> then Apache httpd will redirect them to
    <code>http://www.domain.com/splat/</code>. If you have
    authentication enabled, this will cause the user to have to
    authenticate twice (once for <code>www</code> and once again
    for <code>www.domain.com</code> -- see <a href="http://httpd.apache.org/docs/misc/FAQ.html#prompted-twice">the
    FAQ on this subject for more information</a>). But if
    <code class="directive">UseCanonicalName</code> is set <code>Off</code>, then
    Apache httpd will redirect to <code>http://www/splat/</code>.</p>

    <p>There is a third option, <code>UseCanonicalName DNS</code>,
    which is intended for use with mass IP-based virtual hosting to
    support ancient clients that do not provide a
    <code>Host:</code> header. With this option Apache httpd does a
    reverse DNS lookup on the server IP address that the client
    connected to in order to work out self-referential URLs.</p>

    <div class="warning"><h3>Warning</h3>
    <p>If CGIs make assumptions about the values of <code>SERVER_NAME</code>
    they may be broken by this option. The client is essentially free
    to give whatever value they want as a hostname. But if the CGI is
    only using <code>SERVER_NAME</code> to construct self-referential URLs
    then it should be just fine.</p>
    </div>

<h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#usecanonicalphysicalport">UseCanonicalPhysicalPort</a></code></li>
<li><code class="directive"><a href="#servername">ServerName</a></code></li>
<li><code class="directive"><a href="../mod/mpm_common.html#listen">Listen</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="usecanonicalphysicalport" id="usecanonicalphysicalport">Directiva</a> <a name="UseCanonicalPhysicalPort" id="UseCanonicalPhysicalPort">UseCanonicalPhysicalPort</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Configures how the server determines its own name and
port</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>UseCanonicalPhysicalPort On|Off</code></td></tr>
<tr><th><a href="directive-dict.html#Default">Valor por defecto:</a></th><td><code>UseCanonicalPhysicalPort Off</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config, virtual host, directory</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p>In many situations Apache httpd must construct a <em>self-referential</em>
    URL -- that is, a URL that refers back to the same server. With
    <code>UseCanonicalPhysicalPort On</code> Apache httpd will, when
    constructing the canonical port for the server to honor
    the <code class="directive"><a href="#usecanonicalname">UseCanonicalName</a></code> directive,
    provide the actual physical port number being used by this request
    as a potential port. With <code>UseCanonicalPhysicalPort Off</code>
    Apache httpd will not ever use the actual physical port number, instead
    relying on all configured information to construct a valid port number.</p>

    <div class="note"><h3>Note</h3>
    <p>The ordering of when the physical port is used is as follows:<br /><br />
     <code>UseCanonicalName On</code></p>
     <ul>
      <li>Port provided in <code>Servername</code></li>
      <li>Physical port</li>
      <li>Default port</li>
     </ul>
     <code>UseCanonicalName Off | DNS</code>
     <ul>
      <li>Parsed port from <code>Host:</code> header</li>
      <li>Physical port</li>
      <li>Port provided in <code>Servername</code></li>
      <li>Default port</li>
     </ul>
    
    <p>With <code>UseCanonicalPhysicalPort Off</code>, the
    physical ports are removed from the ordering.</p>
    </div>


<h3>Consulte también</h3>
<ul>
<li><code class="directive"><a href="#usecanonicalname">UseCanonicalName</a></code></li>
<li><code class="directive"><a href="#servername">ServerName</a></code></li>
<li><code class="directive"><a href="../mod/mpm_common.html#listen">Listen</a></code></li>
</ul>
</div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="directive-section"><h2><a name="virtualhost" id="virtualhost">Directiva</a> <a name="VirtualHost" id="VirtualHost">&lt;VirtualHost&gt;</a></h2>
<table class="directive">
<tr><th><a href="directive-dict.html#Description">Descripción:</a></th><td>Contains directives that apply only to a specific
hostname or IP address</td></tr>
<tr><th><a href="directive-dict.html#Syntax">Sintaxis:</a></th><td><code>&lt;VirtualHost
    <var>addr</var>[:<var>port</var>] [<var>addr</var>[:<var>port</var>]]
    ...&gt; ... &lt;/VirtualHost&gt;</code></td></tr>
<tr><th><a href="directive-dict.html#Context">Contexto:</a></th><td>server config</td></tr>
<tr><th><a href="directive-dict.html#Status">Estado:</a></th><td>Core</td></tr>
<tr><th><a href="directive-dict.html#Module">Módulo:</a></th><td>core</td></tr>
</table>
    <p><code class="directive">&lt;VirtualHost&gt;</code> and
    <code>&lt;/VirtualHost&gt;</code> are used to enclose a group of
    directives that will apply only to a particular virtual host. Any
    directive that is allowed in a virtual host context may be
    used. When the server receives a request for a document on a
    particular virtual host, it uses the configuration directives
    enclosed in the <code class="directive">&lt;VirtualHost&gt;</code>
    section. <var>Addr</var> can be:</p>

    <ul>
      <li>The IP address of the virtual host;</li>

      <li>A fully qualified domain name for the IP address of the
      virtual host (not recommended);</li>

      <li>The character <code>*</code>, which is used only in combination with
      <code>NameVirtualHost *</code> to match all IP addresses; or</li>

      <li>The string <code>_default_</code>, which is used only
      with IP virtual hosting to catch unmatched IP addresses.</li>
    </ul>

    <div class="example"><h3>Example</h3><p><code>
      &lt;VirtualHost 10.1.2.3&gt;<br />
      <span class="indent">
        ServerAdmin webmaster@host.example.com<br />
        DocumentRoot /www/docs/host.example.com<br />
        ServerName host.example.com<br />
        ErrorLog logs/host.example.com-error_log<br />
        TransferLog logs/host.example.com-access_log<br />
      </span>
      &lt;/VirtualHost&gt;
    </code></p></div>


    <p>IPv6 addresses must be specified in square brackets because
    the optional port number could not be determined otherwise.  An
    IPv6 example is shown below:</p>

    <div class="example"><p><code>
      &lt;VirtualHost [2001:db8::a00:20ff:fea7:ccea]&gt;<br />
      <span class="indent">
        ServerAdmin webmaster@host.example.com<br />
        DocumentRoot /www/docs/host.example.com<br />
        ServerName host.example.com<br />
        ErrorLog logs/host.example.com-error_log<br />
        TransferLog logs/host.example.com-access_log<br />
      </span>
      &lt;/VirtualHost&gt;
    </code></p></div>

    <p>Each Virtual Host must correspond to a different IP address,
    different port number or a different host name for the server,
    in the former case the server machine must be configured to
    accept IP packets for multiple addresses. (If the machine does
    not have multiple network interfaces, then this can be
    accomplished with the <code>ifconfig alias</code> command -- if
    your OS supports it).</p>

    <div class="note"><h3>Note</h3>
    <p>The use of <code class="directive">&lt;VirtualHost&gt;</code> does
    <strong>not</strong> affect what addresses Apache httpd listens on. You
    may need to ensure that Apache httpd is listening on the correct addresses
    using <code class="directive"><a href="../mod/mpm_common.html#listen">Listen</a></code>.</p>
    </div>

    <p>When using IP-based virtual hosting, the special name
    <code>_default_</code> can be specified in
    which case this virtual host will match any IP address that is
    not explicitly listed in another virtual host. In the absence
    of any <code>_default_</code> virtual host the "main" server config,
    consisting of all those definitions outside any VirtualHost
    section, is used when no IP-match occurs.</p>

    <p>You can specify a <code>:port</code> to change the port that is
    matched. If unspecified then it defaults to the same port as the
    most recent <code class="directive"><a href="../mod/mpm_common.html#listen">Listen</a></code>
    statement of the main server. You may also specify <code>:*</code>
    to match all ports on that address. (This is recommended when used
    with <code>_default_</code>.)</p>

    <p>A <code class="directive"><a href="#servername">ServerName</a></code> should be
    specified inside each <code class="directive">&lt;VirtualHost&gt;</code> block. If it is absent, the
    <code class="directive"><a href="#servername">ServerName</a></code> from the "main"
    server configuration will be inherited.</p>

    <p>If no matching virtual host is found, then the first listed
    virtual host that matches the IP address will be used.  As a
    consequence, the first listed virtual host is the default virtual
    host.</p>

    <div class="warning"><h3>Security</h3>
    <p>See the <a href="../misc/security_tips.html">security tips</a>
    document for details on why your security could be compromised if the
    directory where log files are stored is writable by anyone other
    than the user that starts the server.</p>
    </div>

<h3>Consulte también</h3>
<ul>
<li><a href="../vhosts/">Apache HTTP Server Virtual Host documentation</a></li>
<li><a href="../dns-caveats.html">Issues Regarding DNS and
    Apache HTTP Server</a></li>
<li><a href="../bind.html">Setting
    which addresses and ports Apache HTTP Server uses</a></li>
<li><a href="../sections.html">How &lt;Directory&gt;, &lt;Location&gt;
    and &lt;Files&gt; sections work</a> for an explanation of how these
    different sections are combined when a request is received</li>
</ul>
</div>
</div>
<div class="bottomlang">
<p><span>Idiomas disponibles: </span><a href="../de/mod/core.html" hreflang="de" rel="alternate" title="Deutsch">&nbsp;de&nbsp;</a> |
<a href="../en/mod/core.html" hreflang="en" rel="alternate" title="English">&nbsp;en&nbsp;</a> |
<a href="../es/mod/core.html" title="Español">&nbsp;es&nbsp;</a> |
<a href="../fr/mod/core.html" hreflang="fr" rel="alternate" title="Français">&nbsp;fr&nbsp;</a> |
<a href="../ja/mod/core.html" hreflang="ja" rel="alternate" title="Japanese">&nbsp;ja&nbsp;</a> |
<a href="../tr/mod/core.html" hreflang="tr" rel="alternate" title="Türkçe">&nbsp;tr&nbsp;</a></p>
</div><div class="top"><a href="#page-header"><img src="../images/up.gif" alt="top" /></a></div><div class="section"><h2><a id="comments_section" name="comments_section">Comentarios</a></h2><div class="warning"><strong>Notice:</strong><br />This is not a Q&amp;A section. Comments placed here should be pointed towards suggestions on improving the documentation or server, and may be removed again by our moderators if they are either implemented or considered invalid/off-topic. Questions on how to manage the Apache HTTP Server should be directed at either our IRC channel, #httpd, on Freenode, or sent to our <a href="http://httpd.apache.org/lists.html">mailing lists</a>.</div>
<script type="text/javascript"><!--//--><![CDATA[//><!--
var comments_shortname = 'httpd';
var comments_identifier = 'http://httpd.apache.org/docs/2.4/mod/core.html';
(function(w, d) {
    if (w.location.hostname.toLowerCase() == "httpd.apache.org") {
        d.write('<div id="comments_thread"><\/div>');
        var s = d.createElement('script');
        s.type = 'text/javascript';
        s.async = true;
        s.src = 'https://comments.apache.org/show_comments.lua?site=' + comments_shortname + '&page=' + comments_identifier;
        (d.getElementsByTagName('head')[0] || d.getElementsByTagName('body')[0]).appendChild(s);
    }
    else { 
        d.write('<div id="comments_thread">Comments are disabled for this page at the moment.<\/div>');
    }
})(window, document);
//--><!]]></script></div><div id="footer">
<p class="apache">Copyright 2019 The Apache Software Foundation.<br />Licencia bajo los términos de la <a href="http://www.apache.org/licenses/LICENSE-2.0">Apache License, Version 2.0</a>.</p>
<p class="menu"><a href="../mod/">Módulos</a> | <a href="../mod/directives.html">Directivas</a> | <a href="http://wiki.apache.org/httpd/FAQ">Preguntas Frecuentes</a> | <a href="../glossary.html">Glosario</a> | <a href="../sitemap.html">Mapa del sitio web</a></p></div><script type="text/javascript"><!--//--><![CDATA[//><!--
if (typeof(prettyPrint) !== 'undefined') {
    prettyPrint();
}
//--><!]]></script>
</body></html>