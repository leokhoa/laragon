<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="es" xml:lang="es"><head>
<meta content="text/html; charset=ISO-8859-1" http-equiv="Content-Type" />
<!--
        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
              This file is generated from xml source: DO NOT EDIT
        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      -->
<title>Directorios web por usuario - Servidor HTTP Apache Versión 2.4</title>
<link href="../style/css/manual.css" rel="stylesheet" media="all" type="text/css" title="Main stylesheet" />
<link href="../style/css/manual-loose-100pc.css" rel="alternate stylesheet" media="all" type="text/css" title="No Sidebar - Default font size" />
<link href="../style/css/manual-print.css" rel="stylesheet" media="print" type="text/css" /><link rel="stylesheet" type="text/css" href="../style/css/prettify.css" />
<script src="../style/scripts/prettify.min.js" type="text/javascript">
</script>

<link href="../images/favicon.ico" rel="shortcut icon" /></head>
<body id="manual-page"><div id="page-header">
<p class="menu"><a href="../mod/">Módulos</a> | <a href="../mod/directives.html">Directivas</a> | <a href="http://wiki.apache.org/httpd/FAQ">Preguntas Frecuentes</a> | <a href="../glossary.html">Glosario</a> | <a href="../sitemap.html">Mapa del sitio web</a></p>
<p class="apache">Versión 2.4 del Servidor HTTP Apache</p>
<img alt="" src="../images/feather.png" /></div>
<div class="up"><a href="./"><img title="&lt;-" alt="&lt;-" src="../images/left.gif" /></a></div>
<div id="path">
<a href="http://www.apache.org/">Apache</a> &gt; <a href="http://httpd.apache.org/">Servidor HTTP</a> &gt; <a href="http://httpd.apache.org/docs/">Documentación</a> &gt; <a href="../">Versión 2.4</a> &gt; <a href="./">How-To / Tutorials</a></div><div id="page-content"><div id="preamble"><h1>Directorios web por usuario</h1>
<div class="toplang">
<p><span>Idiomas disponibles: </span><a href="../en/howto/public_html.html" hreflang="en" rel="alternate" title="English">&nbsp;en&nbsp;</a> |
<a href="../es/howto/public_html.html" title="Español">&nbsp;es&nbsp;</a> |
<a href="../fr/howto/public_html.html" hreflang="fr" rel="alternate" title="Français">&nbsp;fr&nbsp;</a> |
<a href="../ja/howto/public_html.html" hreflang="ja" rel="alternate" title="Japanese">&nbsp;ja&nbsp;</a> |
<a href="../ko/howto/public_html.html" hreflang="ko" rel="alternate" title="Korean">&nbsp;ko&nbsp;</a> |
<a href="../tr/howto/public_html.html" hreflang="tr" rel="alternate" title="Türkçe">&nbsp;tr&nbsp;</a></p>
</div>

	<p>En sistemas con múltiples usuarios, cada usuario puede tener un website 
    en su directorio home usando la directiva <code class="directive"><a href="../mod/mod_userdir.html#userdir">UserDir</a></code>. Los visitantes de una URL 
    <code>http://example.com/~username/</code> recibirán el contenido del 
    directorio home del usuario "<code>username</code>", en el subdirectorio 
    especificado por la directiva <code class="directive"><a href="../mod/mod_userdir.html#userdir">UserDir</a></code>.</p>

	<p>Tenga en cuenta que, por defecto, el acceso a estos directorios 
    <strong>NO</strong> está activado. Puede permitir acceso cuando usa 
    <code class="directive"><a href="../mod/mod_userdir.html#userdir">UserDir</a></code> quitando el comentario de la línea:</p>

    <pre class="prettyprint lang-config">#Include conf/extra/httpd-userdir.conf</pre>


    <p>En el fichero por defecto de configuración <code>conf/httpd.conf</code>, 
    y adaptando el fichero <code>httpd-userdir.conf</code> según sea necesario, 
    o incluyendo las directivas apropiadas en un bloque 
    <code class="directive"><a href="../mod/core.html#directory">&lt;Directory&gt;</a></code> dentro del fichero 
    principal de configuración.</p>
</div>
<div id="quickview"><a href="https://www.apache.org/foundation/contributing.html" class="badge"><img src="https://www.apache.org/images/SupportApache-small.png" alt="Support Apache!" /></a><ul id="toc"><li><img alt="" src="../images/down.gif" /> <a href="#related">Directorios web por usuario</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#userdir">Configurando la ruta del fichero con UserDir</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#redirect">Redirigiendo a URLs externas</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#enable">Restringiendo qué usuarios pueden usar esta característica</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#cgi">Activando un directorio cgi para cada usuario</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#htaccess">Permitiendo a usuarios cambiar la configuración</a></li>
</ul><h3>Consulte también</h3><ul class="seealso"><li><a href="../urlmapping.html">Mapeando URLs al sistema de ficheros</a></li><li><a href="#comments_section">Comentarios</a></li></ul></div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="related" id="related">Directorios web por usuario</a></h2>
    
    <table class="related"><tr><th>Módulos Relacionados</th><th>Directivas Relacionadas</th></tr><tr><td><ul><li><code class="module"><a href="../mod/mod_userdir.html">mod_userdir</a></code></li></ul></td><td><ul><li><code class="directive"><a href="../mod/mod_userdir.html#userdir">UserDir</a></code></li><li><code class="directive"><a href="../mod/core.html#directorymatch">DirectoryMatch</a></code></li><li><code class="directive"><a href="../mod/core.html#allowoverride">AllowOverride</a></code></li></ul></td></tr></table>
    </div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="userdir" id="userdir">Configurando la ruta del fichero con UserDir</a></h2>
    

    <p>La directiva <code class="directive"><a href="../mod/mod_userdir.html#userdir">UserDir</a></code>
    especifica un directorio del que cargar contenido por usuario. Esta directiva 
    puede tener muchas formas distintas.</p>

    <p>Si se especifica una ruta que no empieza con una barra ("/"), se asume que 
      va a ser una ruta de directorio relativa al directorio home del usuario 
      especificado. Dada ésta configuración:</p>

    <pre class="prettyprint lang-config">UserDir public_html</pre>


    <p>La URL <code>http://example.com/~rbowen/file.html</code> se traducirá en 
    la ruta del fichero <code>/home/rbowen/public_html/file.html</code></p>

    <p>Si la ruta que se especifica comienza con una barra ("/"), la ruta del 
      directorio se construirá usando esa ruta, más el usuario especificado en la 
      configuración:</p>

    <pre class="prettyprint lang-config">UserDir /var/html</pre>


    <p>La URL <code>http://example.com/~rbowen/file.html</code> se traducirá en 
    la ruta del fichero <code>/var/html/rbowen/file.html</code></p>

    <p>Si se especifica una ruta que contiene un asterisco (*), se usará una ruta 
      en la que el asterisco se reemplaza con el nombre de usuario. Dada ésta configuración:</p>

    <pre class="prettyprint lang-config">UserDir /var/www/*/docs</pre>


    <p>La URL <code>http://example.com/~rbowen/file.html</code> se traducirá en 
    la ruta del fichero <code>/var/www/rbowen/docs/file.html</code></p>

    <p>También se pueden configurar múltiples directorios o rutas de directorios.</p>

    <pre class="prettyprint lang-config">UserDir public_html /var/html</pre>


    <p>Para la URL <code>http://example.com/~rbowen/file.html</code>,
    Apache buscará <code>~rbowen</code>. Si no lo encuentra, Apache buscará
    <code>rbowen</code> en <code>/var/html</code>. Si lo encuentra, la URL de más 
    arriba se traducirá en la ruta del fichero 
    <code>/var/html/rbowen/file.html</code></p>

  </div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="redirect" id="redirect">Redirigiendo a URLs externas</a></h2>
    
    <p>La directiva <code class="directive"><a href="../mod/mod_userdir.html#userdir">UserDir</a></code> puede 
    usarse para redirigir solcitudes de directorios de usuario a URLs externas.</p>

    <pre class="prettyprint lang-config">UserDir http://example.org/users/*/</pre>


    <p>El ejemplo de aquí arriba redirigirá una solicitud para
    <code>http://example.com/~bob/abc.html</code> hacia
    <code>http://example.org/users/bob/abc.html</code>.</p>
  </div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="enable" id="enable">Restringiendo qué usuarios pueden usar esta característica</a></h2>
    

    <p>Usando la sintaxis que se muestra en la documentación de UserDir, usted 
      puede restringir a qué usuarios se les permite usar esta funcionalidad:</p>

    <pre class="prettyprint lang-config">UserDir disabled root jro fish</pre>


    <p>La configuración de aquí arriba permitirá a todos los usuarios excepto a 
      los que se listan con la declaración <code>disabled</code>. Usted puede, 
      del mismo modo, deshabilitar esta característica para todos excepto algunos 
      usuarios usando una configuración como la siguiente:</p>

    <pre class="prettyprint lang-config">UserDir disabled
UserDir enabled rbowen krietz</pre>


    <p>Vea la documentación de <code class="directive"><a href="../mod/mod_userdir.html#userdir">UserDir</a></code> para más 
    ejemplos.</p>

  </div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="cgi" id="cgi">Activando un directorio cgi para cada usuario</a></h2>
  

   <p>Para dar a cada usuario su propio directorio cgi-bin, puede usar una directiva 
   	<code class="directive"><a href="../mod/core.html#directory">&lt;Directory&gt;</a></code>
   para activar cgi en un subdirectorio en particular del directorio home del usuario.</p>

    <pre class="prettyprint lang-config">&lt;Directory "/home/*/public_html/cgi-bin/"&gt;
    Options ExecCGI
    SetHandler cgi-script
&lt;/Directory&gt;</pre>


    <p>Entonces, asumiendo que <code>UserDir</code> está configurado con la 
    declaración <code>public_html</code>, un programa cgi <code>example.cgi</code> 
    podría cargarse de ese directorio así:</p>

    <div class="example"><p><code>
    http://example.com/~rbowen/cgi-bin/example.cgi
    </code></p></div>

    </div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="htaccess" id="htaccess">Permitiendo a usuarios cambiar la configuración</a></h2>
    

    <p>Si quiere permitir que usuarios modifiquen la configuración del servidor en 
    	su espacio web, necesitarán usar ficheros <code>.htaccess</code> para hacer 
    	estos cambios. Asegúrese de tener configurado <code class="directive"><a href="../mod/core.html#allowoverride">AllowOverride</a></code> con un valor suficiente que permita a 
    los usuarios modificar las directivas que quiera permitir. 
    Vea el <a href="htaccess.html">tutorial de .htaccess</a> para obtener detalles adicionales sobre cómo funciona.</p>

  </div></div>
<div class="bottomlang">
<p><span>Idiomas disponibles: </span><a href="../en/howto/public_html.html" hreflang="en" rel="alternate" title="English">&nbsp;en&nbsp;</a> |
<a href="../es/howto/public_html.html" title="Español">&nbsp;es&nbsp;</a> |
<a href="../fr/howto/public_html.html" hreflang="fr" rel="alternate" title="Français">&nbsp;fr&nbsp;</a> |
<a href="../ja/howto/public_html.html" hreflang="ja" rel="alternate" title="Japanese">&nbsp;ja&nbsp;</a> |
<a href="../ko/howto/public_html.html" hreflang="ko" rel="alternate" title="Korean">&nbsp;ko&nbsp;</a> |
<a href="../tr/howto/public_html.html" hreflang="tr" rel="alternate" title="Türkçe">&nbsp;tr&nbsp;</a></p>
</div><div class="top"><a href="#page-header"><img src="../images/up.gif" alt="top" /></a></div><div class="section"><h2><a id="comments_section" name="comments_section">Comentarios</a></h2><div class="warning"><strong>Notice:</strong><br />This is not a Q&amp;A section. Comments placed here should be pointed towards suggestions on improving the documentation or server, and may be removed again by our moderators if they are either implemented or considered invalid/off-topic. Questions on how to manage the Apache HTTP Server should be directed at either our IRC channel, #httpd, on Freenode, or sent to our <a href="http://httpd.apache.org/lists.html">mailing lists</a>.</div>
<script type="text/javascript"><!--//--><![CDATA[//><!--
var comments_shortname = 'httpd';
var comments_identifier = 'http://httpd.apache.org/docs/2.4/howto/public_html.html';
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