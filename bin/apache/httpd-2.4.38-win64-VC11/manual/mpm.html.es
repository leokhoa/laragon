<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="es" xml:lang="es"><head>
<meta content="text/html; charset=ISO-8859-1" http-equiv="Content-Type" />
<!--
        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
              This file is generated from xml source: DO NOT EDIT
        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      -->
<title>Módulos de MultiProcesamiento (MPMs) - Servidor HTTP Apache Versión 2.4</title>
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
<a href="http://www.apache.org/">Apache</a> &gt; <a href="http://httpd.apache.org/">Servidor HTTP</a> &gt; <a href="http://httpd.apache.org/docs/">Documentación</a> &gt; <a href="./">Versión 2.4</a></div><div id="page-content"><div id="preamble"><h1>Módulos de MultiProcesamiento (MPMs)</h1>
<div class="toplang">
<p><span>Idiomas disponibles: </span><a href="./de/mpm.html" hreflang="de" rel="alternate" title="Deutsch">&nbsp;de&nbsp;</a> |
<a href="./en/mpm.html" hreflang="en" rel="alternate" title="English">&nbsp;en&nbsp;</a> |
<a href="./es/mpm.html" title="Español">&nbsp;es&nbsp;</a> |
<a href="./fr/mpm.html" hreflang="fr" rel="alternate" title="Français">&nbsp;fr&nbsp;</a> |
<a href="./ja/mpm.html" hreflang="ja" rel="alternate" title="Japanese">&nbsp;ja&nbsp;</a> |
<a href="./ko/mpm.html" hreflang="ko" rel="alternate" title="Korean">&nbsp;ko&nbsp;</a> |
<a href="./tr/mpm.html" hreflang="tr" rel="alternate" title="Türkçe">&nbsp;tr&nbsp;</a> |
<a href="./zh-cn/mpm.html" hreflang="zh-cn" rel="alternate" title="Simplified Chinese">&nbsp;zh-cn&nbsp;</a></p>
</div>

<p>Este documento describe que es un Módulo de Multiprocesamiento y
como los usa Apache.</p>
</div>
<div id="quickview"><a href="https://www.apache.org/foundation/contributing.html" class="badge"><img src="https://www.apache.org/images/SupportApache-small.png" alt="Support Apache!" /></a><ul id="toc"><li><img alt="" src="./images/down.gif" /> <a href="#introduction">Introducción</a></li>
<li><img alt="" src="./images/down.gif" /> <a href="#defaults">MPM por defecto</a></li>
</ul><h3>Consulte también</h3><ul class="seealso"><li><a href="#comments_section">Comentarios</a></li></ul></div>
<div class="top"><a href="#page-header"><img alt="top" src="./images/up.gif" /></a></div>
<div class="section">
<h2><a name="introduction" id="introduction">Introducción</a></h2>

    <p>Apache está diseñado para ser un servidor web potente
    y flexible que pueda funcionar en la más amplia variedad de
    plataformas y entornos. Las diferentes plataformas y los
    diferentes entornos, hacen que a menudo sean necesarias diferentes
    características o funcionalidades, o que una misma
    característica o funcionalidad sea implementada de diferente
    manera para obtener una mayor eficiencia. Apache se ha adaptado
    siempre a una gran variedad de entornos a través de su
    diseño modular. Este diseño permite a los
    administradores de sitios web elegir que características van
    a ser incluidas en el servidor seleccionando que módulos se
    van a cargar, ya sea al compilar o en tiempo de ejecución.</p>

    <p>Apache 2.0 extiende este diseño modular hasta las
    funciones más básicas de un servidor web. El servidor
    viene con una serie de Módulos de MultiProcesamiento que son
    responsables de conectar con los puertos de red de la
    máquina, aceptar las peticiones, y generar los procesos hijo
    que se encargan de servirlas.</p>

    <p>La extensión del diseño modular a este nivel del
    servidor ofrece dos beneficios importantes:</p>

    <ul>
      <li>Apache puede soportar de una forma más fácil y
      eficiente una amplia variedad de sistemas operativos. En
      concreto, la versión de Windows de Apache es mucho más
      eficiente, porque el módulo <code class="module"><a href="./mod/mpm_winnt.html">mpm_winnt</a></code>
      puede usar funcionalidades nativas de red en lugar de usar la
      capa POSIX como hace Apache 1.3. Este beneficio se extiende
      también a otros sistemas operativos que implementan sus
      respectivos MPMs.</li>

      <li>El servidor puede personalizarse mejor para las necesidades
      de cada sitio web. Por ejemplo, los sitios web que necesitan
      más que nada escalabilidad pueden usar un proceso MPM como
      <code class="module"><a href="./mod/worker.html">worker</a></code>, mientras que los sitios web que
      requieran por encima de otras cosas estabilidad o compatibilidad
      con software antiguo pueden usar
      <code class="module"><a href="./mod/prefork.html">prefork</a></code>.
      </li>
    </ul>

    <p>A nivel de usuario, los MPMs son como cualquier otro
    módulo de Apache. La diferencia más importante es que
    solo un MPM puede estar cargado en el servidor en un determinado
    momento. La lista de MPMs disponibles está en la <a href="mod/">sección índice de Módulos</a>.</p>

</div><div class="top"><a href="#page-header"><img alt="top" src="./images/up.gif" /></a></div>
<div class="section">
<h2><a name="defaults" id="defaults">MPM por defecto</a></h2>

<p>En la siguiente tabla se muestran los MPMs por defecto para varios
sistemas operativos.  Estos serán los MPM seleccionados si no se
especifica lo contrario al compilar.</p>

<table class="bordered"><tr><td>Netware</td><td><code class="module"><a href="./mod/mpm_netware.html">mpm_netware</a></code></td></tr>
<tr class="odd"><td>OS/2</td><td><code class="module"><a href="./mod/mpmt_os2.html">mpmt_os2</a></code></td></tr>
<tr><td>Unix</td><td><code class="module"><a href="./mod/prefork.html">prefork</a></code>, <code class="module"><a href="./mod/worker.html">worker</a></code>, or
    <code class="module"><a href="./mod/event.html">event</a></code>, depending on platform capabilities</td></tr>
<tr class="odd"><td>Windows</td><td><code class="module"><a href="./mod/mpm_winnt.html">mpm_winnt</a></code></td></tr>
</table>

<div class="note"><p>aquí, 'Unix' se usa para designar a los sistemas operativos "Unix-like", como
Linux, BSD, Solaris, Mac OS X, etc.</p></div>

<p>En el caso de los Unix, la decisión de que MPM se va a instalar
  depende de dos pregunas:</p>
<p>1. ¿Nos permite el Sistema Operativo hilos?</p>
<p>2. -¿Nos permite el sistema operativo soporte a pila de hilos seguros 
  (Especificamente, las funciones kqueue y epoll)?</p>
</div></div>
<div class="bottomlang">
<p><span>Idiomas disponibles: </span><a href="./de/mpm.html" hreflang="de" rel="alternate" title="Deutsch">&nbsp;de&nbsp;</a> |
<a href="./en/mpm.html" hreflang="en" rel="alternate" title="English">&nbsp;en&nbsp;</a> |
<a href="./es/mpm.html" title="Español">&nbsp;es&nbsp;</a> |
<a href="./fr/mpm.html" hreflang="fr" rel="alternate" title="Français">&nbsp;fr&nbsp;</a> |
<a href="./ja/mpm.html" hreflang="ja" rel="alternate" title="Japanese">&nbsp;ja&nbsp;</a> |
<a href="./ko/mpm.html" hreflang="ko" rel="alternate" title="Korean">&nbsp;ko&nbsp;</a> |
<a href="./tr/mpm.html" hreflang="tr" rel="alternate" title="Türkçe">&nbsp;tr&nbsp;</a> |
<a href="./zh-cn/mpm.html" hreflang="zh-cn" rel="alternate" title="Simplified Chinese">&nbsp;zh-cn&nbsp;</a></p>
</div><div class="top"><a href="#page-header"><img src="./images/up.gif" alt="top" /></a></div><div class="section"><h2><a id="comments_section" name="comments_section">Comentarios</a></h2><div class="warning"><strong>Notice:</strong><br />This is not a Q&amp;A section. Comments placed here should be pointed towards suggestions on improving the documentation or server, and may be removed again by our moderators if they are either implemented or considered invalid/off-topic. Questions on how to manage the Apache HTTP Server should be directed at either our IRC channel, #httpd, on Freenode, or sent to our <a href="http://httpd.apache.org/lists.html">mailing lists</a>.</div>
<script type="text/javascript"><!--//--><![CDATA[//><!--
var comments_shortname = 'httpd';
var comments_identifier = 'http://httpd.apache.org/docs/2.4/mpm.html';
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