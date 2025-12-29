<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="es" xml:lang="es"><head>
<meta content="text/html; charset=ISO-8859-1" http-equiv="Content-Type" />
<!--
        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
              This file is generated from xml source: DO NOT EDIT
        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      -->
<title>Uso de los Handlers en Apache - Servidor HTTP Apache Versión 2.4</title>
<link href="./style/css/manual.css" rel="stylesheet" media="all" type="text/css" title="Main stylesheet" />
<link href="./style/css/manual-loose-100pc.css" rel="alternate stylesheet" media="all" type="text/css" title="No Sidebar - Default font size" />
<link href="./style/css/manual-print.css" rel="stylesheet" media="print" type="text/css" /><link rel="stylesheet" type="text/css" href="./style/css/prettify.css" />
<script src="./style/scripts/prettify.min.js" type="text/javascript">
</script>

<link href="./images/favicon.ico" rel="shortcut icon" /></head>
<body id="manual-page"><div id="page-header">
<p class="menu"><a href="./mod/">Módulos</a> | <a href="./mod/directives.html">Directivas</a> | <a href="http://wiki.apache.org/httpd/FAQ">Preguntas Frecuentes</a> | <a href="./glossary.html">Glosario</a> | <a href="./sitemap.html">Mapa del sitio web</a></p>
<p class="apache">Versión 2.4 del Servidor HTTP Apache</p>
<img alt="" src="./images/feather.png" /></div>
<div class="up"><a href="./"><img title="&lt;-" alt="&lt;-" src="./images/left.gif" /></a></div>
<div id="path">
<a href="http://www.apache.org/">Apache</a> &gt; <a href="http://httpd.apache.org/">Servidor HTTP</a> &gt; <a href="http://httpd.apache.org/docs/">Documentación</a> &gt; <a href="./">Versión 2.4</a></div><div id="page-content"><div id="preamble"><h1>Uso de los Handlers en Apache</h1>
<div class="toplang">
<p><span>Idiomas disponibles: </span><a href="./en/handler.html" hreflang="en" rel="alternate" title="English">&nbsp;en&nbsp;</a> |
<a href="./es/handler.html" title="Español">&nbsp;es&nbsp;</a> |
<a href="./fr/handler.html" hreflang="fr" rel="alternate" title="Français">&nbsp;fr&nbsp;</a> |
<a href="./ja/handler.html" hreflang="ja" rel="alternate" title="Japanese">&nbsp;ja&nbsp;</a> |
<a href="./ko/handler.html" hreflang="ko" rel="alternate" title="Korean">&nbsp;ko&nbsp;</a> |
<a href="./tr/handler.html" hreflang="tr" rel="alternate" title="Türkçe">&nbsp;tr&nbsp;</a> |
<a href="./zh-cn/handler.html" hreflang="zh-cn" rel="alternate" title="Simplified Chinese">&nbsp;zh-cn&nbsp;</a></p>
</div>

    <p>Este documento describe el uso de los Handlers en Apache.</p>
  </div>
<div id="quickview"><a href="https://www.apache.org/foundation/contributing.html" class="badge"><img src="https://www.apache.org/images/SupportApache-small.png" alt="Support Apache!" /></a><ul id="toc"><li><img alt="" src="./images/down.gif" /> <a href="#definition">¿Qué es un Handler?</a></li>
<li><img alt="" src="./images/down.gif" /> <a href="#examples">Ejemplos</a></li>
<li><img alt="" src="./images/down.gif" /> <a href="#programmer">Nota para programadores</a></li>
</ul><h3>Consulte también</h3><ul class="seealso"><li><a href="#comments_section">Comentarios</a></li></ul></div>
<div class="top"><a href="#page-header"><img alt="top" src="./images/up.gif" /></a></div>
<div class="section">
<h2><a name="definition" id="definition">¿Qué es un Handler?</a></h2>
    
    <table class="related"><tr><th>Módulos Relacionados</th><th>Directivas Relacionadas</th></tr><tr><td><ul><li><code class="module"><a href="./mod/mod_actions.html">mod_actions</a></code></li><li><code class="module"><a href="./mod/mod_asis.html">mod_asis</a></code></li><li><code class="module"><a href="./mod/mod_cgi.html">mod_cgi</a></code></li><li><code class="module"><a href="./mod/mod_imagemap.html">mod_imagemap</a></code></li><li><code class="module"><a href="./mod/mod_info.html">mod_info</a></code></li><li><code class="module"><a href="./mod/mod_mime.html">mod_mime</a></code></li><li><code class="module"><a href="./mod/mod_negotiation.html">mod_negotiation</a></code></li><li><code class="module"><a href="./mod/mod_status.html">mod_status</a></code></li></ul></td><td><ul><li><code class="directive"><a href="./mod/mod_actions.html#action">Action</a></code></li><li><code class="directive"><a href="./mod/mod_mime.html#addhandler">AddHandler</a></code></li><li><code class="directive"><a href="./mod/mod_mime.html#removehandler">RemoveHandler</a></code></li><li><code class="directive"><a href="./mod/core.html#sethandler">SetHandler</a></code></li></ul></td></tr></table>


    <p>Un "handler" es una representación interna de Apache de
    una acción que se va a ejecutar cuando hay una llamada a un
    fichero. Generalmente, los ficheros tienen handlers
    implícitos, basados en el tipo de fichero de que se
    trata. Normalmente, todos los ficheros son simplemente servidos
    por el servidor, pero algunos tipos de ficheros se tratan de forma
    diferente.</p>

    <p>Handlers pueden ser usados de manera explicita,
     basándose en la extensión del fichero o en
    la ubicación en la que esté, se pueden especificar handlers
    sin tener en cuenta el tipo de fichero que se trate. Esto es
    una ventaja por dos razones. Primero, es una solución
    más elegante. Segundo, porque a un fichero se le pueden
    asignar tanto un tipo <strong>como</strong> un handler. (Consulte
    también la sección <a href="mod/mod_mime.html#multipleext">Ficheros y extensiones
    múltiples</a>.)</p>

    <p>Los Handlers pueden tanto ser compilados con el servidor
    como incluidos en un módulo, o añadidos con la
    directiva <code class="directive"><a href="./mod/mod_actions.html#action">Action</a></code>. Los
    handlers que vienen incluidos en el core con el servidor de la distribución
    estándar de Apache son:</p>

    <ul>
      <li><strong>default-handler</strong>: Envía el fichero
      usando el <code>default_handler()</code>, que es el handler
      usado por defecto para tratar contenido
      estático. (core)</li>

      <li><strong>send-as-is</strong>: Envía el fichero con
      cabeceras HTTP tal y como es. (<code class="module"><a href="./mod/mod_asis.html">mod_asis</a></code>)</li>

      <li><strong>cgi-script</strong>: Trata el fichero como un sript
      CGI. (<code class="module"><a href="./mod/mod_cgi.html">mod_cgi</a></code>)</li>

      <li><strong>imap-file</strong>: Trata el fichero como un mapa de
      imágenes. (<code class="module"><a href="./mod/mod_imagemap.html">mod_imagemap</a></code>)</li>

      <li><strong>server-info</strong>: Extrae la información de
      configuración del
      servidor. (<code class="module"><a href="./mod/mod_info.html">mod_info</a></code>)</li>

      <li><strong>server-status</strong>: Extrae el informe del estado
      del servidor. (<code class="module"><a href="./mod/mod_status.html">mod_status</a></code>)</li>

      <li><strong>type-map</strong>: Trata el fichero como una
      correspondencia de tipos para la negociación de contenidos.
      (<code class="module"><a href="./mod/mod_negotiation.html">mod_negotiation</a></code>)</li> 
    </ul> 
  </div><div class="top"><a href="#page-header"><img alt="top" src="./images/up.gif" /></a></div>
<div class="section">
<h2><a name="examples" id="examples">Ejemplos</a></h2> 
      

      <h3><a name="example1" id="example1">Modificar contenido estático usando un script
      CGI</a></h3>
      

      <p>Las siguientes directivas hacen que cuando haya una
      petición de ficheros con la extensión
      <code>html</code> se lance el script CGI
      <code>footer.pl</code>.</p>

      <div class="example"><p><code>
        Action add-footer /cgi-bin/footer.pl<br />
        AddHandler add-footer .html
      </code></p></div>

      <p>En este caso, el script CGI es el responsable de enviar el
      documento originalmente solicitado (contenido en la variable de
      entorno <code>PATH_TRANSLATED</code>) y de hacer cualquier
      modificación o añadido deseado.</p>

    
    <h3><a name="example2" id="example2">Archivos con cabeceras HTTP</a></h3>
      

      <p>Las siguientes directivas activan el handler
      <code>send-as-is</code>, que se usa para ficheros que contienen
      sus propias cabeceras HTTP. Todos los archivos en el directorio
      <code>/web/htdocs/asis/</code> serán procesados por el
      handler <code>send-as-is</code>, sin tener en cuenta su
      extension.</p>

      <pre class="prettyprint lang-config">&lt;Directory "/web/htdocs/asis"&gt;
    SetHandler send-as-is
&lt;/Directory&gt;</pre>


    
  </div><div class="top"><a href="#page-header"><img alt="top" src="./images/up.gif" /></a></div>
<div class="section">
<h2><a name="programmer" id="programmer">Nota para programadores</a></h2>
    

    <p>Para implementar las funcionalidades de los handlers, se ha
    hecho un añadido a la <a href="developer/API.html">API de
    Apache</a> que puede que quiera usar. Para ser más
    específicos, se ha añadido un nuevo registro a la
    estructura <code>request_rec</code>:</p>

    <pre class="prettyprint lang-c">char *handler</pre>


    <p>Si quiere que su módulo llame a un handler , solo tiene
    que añadir <code>r-&gt;handler</code> al nombre del handler
    en cualquier momento antes de la fase <code>invoke_handler</code>
    de la petición. Los handlers se implementan siempre como se
    hacía antes, aunque usando el nombre del handler en vez de un
    tipo de contenido. Aunque no es de obligado cumplimiento, la
    convención de nombres para los handlers es que se usen
    palabras separadas por guiones, sin barras, de manera que no se
    invada el media type name-space.</p>
  </div></div>
<div class="bottomlang">
<p><span>Idiomas disponibles: </span><a href="./en/handler.html" hreflang="en" rel="alternate" title="English">&nbsp;en&nbsp;</a> |
<a href="./es/handler.html" title="Español">&nbsp;es&nbsp;</a> |
<a href="./fr/handler.html" hreflang="fr" rel="alternate" title="Français">&nbsp;fr&nbsp;</a> |
<a href="./ja/handler.html" hreflang="ja" rel="alternate" title="Japanese">&nbsp;ja&nbsp;</a> |
<a href="./ko/handler.html" hreflang="ko" rel="alternate" title="Korean">&nbsp;ko&nbsp;</a> |
<a href="./tr/handler.html" hreflang="tr" rel="alternate" title="Türkçe">&nbsp;tr&nbsp;</a> |
<a href="./zh-cn/handler.html" hreflang="zh-cn" rel="alternate" title="Simplified Chinese">&nbsp;zh-cn&nbsp;</a></p>
</div><div class="top"><a href="#page-header"><img src="./images/up.gif" alt="top" /></a></div><div class="section"><h2><a id="comments_section" name="comments_section">Comentarios</a></h2><div class="warning"><strong>Notice:</strong><br />This is not a Q&amp;A section. Comments placed here should be pointed towards suggestions on improving the documentation or server, and may be removed again by our moderators if they are either implemented or considered invalid/off-topic. Questions on how to manage the Apache HTTP Server should be directed at either our IRC channel, #httpd, on Freenode, or sent to our <a href="http://httpd.apache.org/lists.html">mailing lists</a>.</div>
<script type="text/javascript"><!--//--><![CDATA[//><!--
var comments_shortname = 'httpd';
var comments_identifier = 'http://httpd.apache.org/docs/2.4/handler.html';
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
<p class="menu"><a href="./mod/">Módulos</a> | <a href="./mod/directives.html">Directivas</a> | <a href="http://wiki.apache.org/httpd/FAQ">Preguntas Frecuentes</a> | <a href="./glossary.html">Glosario</a> | <a href="./sitemap.html">Mapa del sitio web</a></p></div><script type="text/javascript"><!--//--><![CDATA[//><!--
if (typeof(prettyPrint) !== 'undefined') {
    prettyPrint();
}
//--><!]]></script>
</body></html>