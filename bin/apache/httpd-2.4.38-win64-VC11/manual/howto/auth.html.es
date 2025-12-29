<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="es" xml:lang="es"><head>
<meta content="text/html; charset=ISO-8859-1" http-equiv="Content-Type" />
<!--
        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
              This file is generated from xml source: DO NOT EDIT
        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      -->
<title>Autenticación y Autorización - Servidor HTTP Apache Versión 2.4</title>
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
<a href="http://www.apache.org/">Apache</a> &gt; <a href="http://httpd.apache.org/">Servidor HTTP</a> &gt; <a href="http://httpd.apache.org/docs/">Documentación</a> &gt; <a href="../">Versión 2.4</a> &gt; <a href="./">How-To / Tutoriales</a></div><div id="page-content"><div id="preamble"><h1>Autenticación y Autorización</h1>
<div class="toplang">
<p><span>Idiomas disponibles: </span><a href="../en/howto/auth.html" hreflang="en" rel="alternate" title="English">&nbsp;en&nbsp;</a> |
<a href="../es/howto/auth.html" title="Español">&nbsp;es&nbsp;</a> |
<a href="../fr/howto/auth.html" hreflang="fr" rel="alternate" title="Français">&nbsp;fr&nbsp;</a> |
<a href="../ja/howto/auth.html" hreflang="ja" rel="alternate" title="Japanese">&nbsp;ja&nbsp;</a> |
<a href="../ko/howto/auth.html" hreflang="ko" rel="alternate" title="Korean">&nbsp;ko&nbsp;</a> |
<a href="../tr/howto/auth.html" hreflang="tr" rel="alternate" title="Türkçe">&nbsp;tr&nbsp;</a></p>
</div>

    <p>Autenticación es cualquier proceso por el cuál se verifica que uno es 
    quien dice ser. Autorización es cualquier proceso en el cuál cualquiera
    está permitido a estar donde se quiera, o tener información la cuál se
    quiera tener.
    </p>

    <p>Para información de control de acceso de forma genérica visite<a href="access.html">How to de Control de Acceso</a>.</p>
</div>
<div id="quickview"><a href="https://www.apache.org/foundation/contributing.html" class="badge"><img src="https://www.apache.org/images/SupportApache-small.png" alt="Support Apache!" /></a><ul id="toc"><li><img alt="" src="../images/down.gif" /> <a href="#related">Módulos y Directivas Relacionados</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#introduction">Introducción</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#theprerequisites">Los Prerequisitos</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#gettingitworking">Conseguir que funcione</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#lettingmorethanonepersonin">Dejar que más de una persona 
	entre</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#possibleproblems">Posibles Problemas</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#dbmdbd">Método alternativo de almacenamiento de las 
	contraseñas</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#multprovider">Uso de múltiples proveedores</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#beyond">Más allá de la Autorización</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#socache">Cache de Autenticación</a></li>
<li><img alt="" src="../images/down.gif" /> <a href="#moreinformation">Más información</a></li>
</ul><h3>Consulte también</h3><ul class="seealso"><li><a href="#comments_section">Comentarios</a></li></ul></div>
<div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="related" id="related">Módulos y Directivas Relacionados</a></h2>

<p>Hay tres tipos de módulos involucrados en los procesos de la autenticación 
	y autorización. Normalmente deberás escoger al menos un módulo de cada grupo.</p>

<ul>
  <li>Modos de Autenticación (consulte la directiva
      <code class="directive"><a href="../mod/mod_authn_core.html#authtype">AuthType</a></code> )
    <ul>
      <li><code class="module"><a href="../mod/mod_auth_basic.html">mod_auth_basic</a></code></li>
      <li><code class="module"><a href="../mod/mod_auth_digest.html">mod_auth_digest</a></code></li>
    </ul>
  </li>
  <li>Proveedor de Autenticación (consulte la directiva
  <code class="directive"><a href="../mod/mod_auth_basic.html#authbasicprovider">AuthBasicProvider</a></code> y
  <code class="directive"><a href="../mod/mod_auth_digest.html#authdigestprovider">AuthDigestProvider</a></code>)

    <ul>
      <li><code class="module"><a href="../mod/mod_authn_anon.html">mod_authn_anon</a></code></li>
      <li><code class="module"><a href="../mod/mod_authn_dbd.html">mod_authn_dbd</a></code></li>
      <li><code class="module"><a href="../mod/mod_authn_dbm.html">mod_authn_dbm</a></code></li>
      <li><code class="module"><a href="../mod/mod_authn_file.html">mod_authn_file</a></code></li>
      <li><code class="module"><a href="../mod/mod_authnz_ldap.html">mod_authnz_ldap</a></code></li>
      <li><code class="module"><a href="../mod/mod_authn_socache.html">mod_authn_socache</a></code></li>
    </ul>
  </li>
  <li>Autorización (consulte la directiva
      <code class="directive"><a href="../mod/mod_authz_core.html#require">Require</a></code>)
    <ul>
      <li><code class="module"><a href="../mod/mod_authnz_ldap.html">mod_authnz_ldap</a></code></li>
      <li><code class="module"><a href="../mod/mod_authz_dbd.html">mod_authz_dbd</a></code></li>
      <li><code class="module"><a href="../mod/mod_authz_dbm.html">mod_authz_dbm</a></code></li>
      <li><code class="module"><a href="../mod/mod_authz_groupfile.html">mod_authz_groupfile</a></code></li>
      <li><code class="module"><a href="../mod/mod_authz_host.html">mod_authz_host</a></code></li>
      <li><code class="module"><a href="../mod/mod_authz_owner.html">mod_authz_owner</a></code></li>
      <li><code class="module"><a href="../mod/mod_authz_user.html">mod_authz_user</a></code></li>
    </ul>
  </li>
</ul>

  <p>A parte de éstos módulos, también están
  <code class="module"><a href="../mod/mod_authn_core.html">mod_authn_core</a></code> y
  <code class="module"><a href="../mod/mod_authz_core.html">mod_authz_core</a></code>. Éstos módulos implementan las directivas 
  esenciales que son el centro de todos los módulos de autenticación.</p>

  <p>El módulo <code class="module"><a href="../mod/mod_authnz_ldap.html">mod_authnz_ldap</a></code> es tanto un proveedor de 
  autenticación como de autorización. El módulo
  <code class="module"><a href="../mod/mod_authz_host.html">mod_authz_host</a></code> proporciona autorización y control de acceso
  basado en el nombre del Host, la dirección IP o características de la propia
  petición, pero no es parte del sistema proveedor de 
  autenticación. Para tener compatibilidad inversa con el mod_access, 
  hay un nuevo modulo llamado <code class="module"><a href="../mod/mod_access_compat.html">mod_access_compat</a></code>.</p>

  <p>También puedes mirar el how-to de <a href="access.html">Control de Acceso </a>, donde se plantean varias formas del control de acceso al servidor.</p>

</div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="introduction" id="introduction">Introducción</a></h2>
    <p>Si se tiene información en nuestra página web que sea información 
    	sensible o pensada para un grupo reducido de usuarios/personas,
    	las técnicas que se describen en este manual, le servirán  
    	de ayuda para asegurarse de que las personas que ven esas páginas sean 
    	las personas que uno quiere.</p>

    <p>Este artículo cubre la parte "estándar" de cómo proteger partes de un 
    	sitio web que muchos usarán.</p>

    <div class="note"><h3>Nota:</h3>
    <p>Si de verdad es necesario que tus datos estén en un sitio seguro, 
    	considera usar <code class="module"><a href="../mod/mod_ssl.html">mod_ssl</a></code>  como método de autenticación adicional a cualquier forma de autenticación.</p>
    </div>
</div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="theprerequisites" id="theprerequisites">Los Prerequisitos</a></h2>
    <p>Las directivas que se usan en este artículo necesitaran ponerse ya sea 
    	en el fichero de configuración principal del servidor ( típicamente en 
    	la sección 
    <code class="directive"><a href="../mod/core.html#directory">&lt;Directory&gt;</a></code> de httpd.conf ), o
    en cada uno de los ficheros de configuraciones del propio directorio
    (los archivos <code>.htaccess</code>).</p>

    <p>Si planea usar los ficheros <code>.htaccess</code> , necesitarás
    tener en la configuración global del servidor, una configuración que permita
    poner directivas de autenticación en estos ficheros. Esto se hace con la
    directiva <code class="directive"><a href="../mod/core.html#allowoverride">AllowOverride</a></code>, la cual especifica
    que directivas, en su caso, pueden ser puestas en cada fichero de configuración
    por directorio.</p>

    <p>Ya que estamos hablando aquí de autenticación, necesitarás una directiva 
    	<code class="directive"><a href="../mod/core.html#allowoverride">AllowOverride</a></code> como la siguiente:
    	</p>

    <pre class="prettyprint lang-config">AllowOverride AuthConfig</pre>


    <p>O, si solo se van a poner las directivas directamente en la configuración
    	principal del servidor, deberás tener, claro está, permisos de escritura
    	en el archivo. </p>

    <p>Y necesitarás saber un poco de como está estructurado el árbol de 
    	directorios de tu servidor, para poder saber donde se encuentran algunos 
    	archivos. Esto no debería ser una tarea difícil, aún así intentaremos 
    	dejarlo claro llegado el momento de comentar dicho aspecto.</p>

    <p>También deberás de asegurarte de que los módulos 
    <code class="module"><a href="../mod/mod_authn_core.html">mod_authn_core</a></code> y <code class="module"><a href="../mod/mod_authz_core.html">mod_authz_core</a></code>
    han sido incorporados, o añadidos a la hora de compilar en tu binario httpd o
    cargados mediante el archivo de configuración <code>httpd.conf</code>. Estos 
    dos módulos proporcionan directivas básicas y funcionalidades que son críticas
    para la configuración y uso de autenticación y autorización en el servidor web.</p>
</div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="gettingitworking" id="gettingitworking">Conseguir que funcione</a></h2>
    <p>Aquí está lo básico de cómo proteger con contraseña un directorio en tu
     servidor.</p>

    <p>Primero, necesitarás crear un fichero de contraseña. Dependiendo de que 
    	proveedor de autenticación se haya elegido, se hará de una forma u otra. Para empezar, 
    	usaremos un fichero de contraseña de tipo texto.</p>

    <p>Este fichero deberá estar en un sitio que no se pueda tener acceso desde
     la web. Esto también implica que nadie pueda descargarse el fichero de 
     contraseñas. Por ejemplo, si tus documentos están guardados fuera de
     <code>/usr/local/apache/htdocs</code>, querrás poner tu archivo de contraseñas en 
     <code>/usr/local/apache/passwd</code>.</p>

    <p>Para crear el fichero de contraseñas, usa la utilidad 
    	<code class="program"><a href="../programs/htpasswd.html">htpasswd</a></code> que viene con Apache. Esta herramienta se 
    	encuentra en el directorio <code>/bin</code> en donde sea que se ha 
    	instalado el Apache. Si ha instalado Apache desde un paquete de terceros, 
    	puede ser que se encuentre en su ruta de ejecución.</p>

    <p>Para crear el fichero, escribiremos:</p>

    <div class="example"><p><code>
      htpasswd -c /usr/local/apache/passwd/passwords rbowen
    </code></p></div>

    <p><code class="program"><a href="../programs/htpasswd.html">htpasswd</a></code> te preguntará por una contraseña, y después 
    te pedirá que la vuelvas a escribir para confirmarla:</p>

    <div class="example"><p><code>
      $ htpasswd -c /usr/local/apache/passwd/passwords rbowen<br />
      New password: mypassword<br />
      Re-type new password: mypassword<br />
      Adding password for user rbowen
    </code></p></div>

    <p>Si <code class="program"><a href="../programs/htpasswd.html">htpasswd</a></code> no está en tu variable de entorno "path" del 
    sistema, por supuesto deberás escribir la ruta absoluta del ejecutable para 
    poder hacer que se ejecute. En una instalación por defecto, está en:
    <code>/usr/local/apache2/bin/htpasswd</code></p>

    <p>Lo próximo que necesitas, será configurar el servidor para que pida una 
    	contraseña y así decirle al servidor que usuarios están autorizados a acceder.
    	Puedes hacer esto ya sea editando el fichero <code>httpd.conf</code>
    de configuración  o usando in fichero <code>.htaccess</code>. Por ejemplo, 
    si quieres proteger el directorio
    <code>/usr/local/apache/htdocs/secret</code>, puedes usar las siguientes 
    directivas, ya sea en el fichero <code>.htaccess</code> localizado en
    following directives, either placed in the file
    <code>/usr/local/apache/htdocs/secret/.htaccess</code>, o
    en la configuración global del servidor <code>httpd.conf</code> dentro de la
    sección &lt;Directory  
    "/usr/local/apache/htdocs/secret"&gt; , como se muestra a continuación:</p>

    <pre class="prettyprint lang-config">&lt;Directory "/usr/local/apache/htdocs/secret"&gt;
AuthType Basic
AuthName "Restricted Files"
# (Following line optional)
AuthBasicProvider file
AuthUserFile "/usr/local/apache/passwd/passwords"
Require user rbowen
&lt;/Directory&gt;</pre>


    <p>Vamos a explicar cada una de las directivas individualmente.
    	La directiva <code class="directive"><a href="../mod/mod_authn_core.html#authtype">AuthType</a></code> selecciona el método
    que se usa para autenticar al usuario. El método más común es 
    <code>Basic</code>, y éste es el método que implementa 
    <code class="module"><a href="../mod/mod_auth_basic.html">mod_auth_basic</a></code>. Es muy importante ser consciente,
    de que la autenticación básica, envía las contraseñas desde el cliente 
    al servidor sin cifrar.
    Este método por tanto, no debe ser utilizado para proteger datos muy sensibles,
    a no ser que, este método de autenticación básica, sea acompañado del módulo
    <code class="module"><a href="../mod/mod_ssl.html">mod_ssl</a></code>.
    Apache soporta otro método más de autenticación  que es del tipo 
    <code>AuthType Digest</code>. Este método, es implementado por el módulo <code class="module"><a href="../mod/mod_auth_digest.html">mod_auth_digest</a></code> y con el se pretendía crear una autenticación más
    segura. Este ya no es el caso, ya que la conexión deberá realizarse con  <code class="module"><a href="../mod/mod_ssl.html">mod_ssl</a></code> en su lugar.
    </p>

    <p>La directiva <code class="directive"><a href="../mod/mod_authn_core.html#authname">AuthName</a></code> 
    establece el <dfn>Realm</dfn> para ser usado en la autenticación. El 
    <dfn>Realm</dfn> tiene dos funciones principales.
    La primera, el cliente presenta a menudo esta información al usuario como 
    parte del cuadro de diálogo de contraseña. La segunda, que es utilizado por 
    el cliente para determinar qué contraseña enviar a para una determinada zona 
    de autenticación.</p>

    <p>Así que, por ejemple, una vez que el cliente se ha autenticado en el área de
    los <code>"Ficheros Restringidos"</code>, entonces re-intentará automáticamente
    la misma contraseña para cualquier área en el mismo servidor que es marcado 
    con el Realm de <code>"Ficheros Restringidos"</code>
    Por lo tanto, puedes prevenir que a un usuario se le pida mas de una vez por su
    contraseña, compartiendo así varias áreas restringidas el mismo Realm
    Por supuesto, por razones de seguridad, el cliente pedirá siempre por una contraseña, 
    siempre y cuando el nombre del servidor cambie.
    </p>

    <p>La directiva <code class="directive"><a href="../mod/mod_auth_basic.html#authbasicprovider">AuthBasicProvider</a></code> es,
    en este caso, opcional, ya que <code>file</code> es el valor por defecto
    para esta directiva. Deberás usar esta directiva si estas usando otro medio
    diferente para la autenticación, como por ejemplo
    <code class="module"><a href="../mod/mod_authn_dbm.html">mod_authn_dbm</a></code> o <code class="module"><a href="../mod/mod_authn_dbd.html">mod_authn_dbd</a></code>.</p>

    <p>La directiva <code class="directive"><a href="../mod/mod_authn_file.html#authuserfile">AuthUserFile</a></code>
    establece el path al fichero de contraseñas que acabamos de crear con el 
    comando <code class="program"><a href="../programs/htpasswd.html">htpasswd</a></code>. Si tiene un número muy grande de usuarios, 
    puede ser realmente lento el buscar el usuario en ese fichero de texto plano 
    para autenticar a los usuarios en cada petición.
    Apache también tiene la habilidad de almacenar información de usuarios en 
    unos ficheros de rápido acceso a modo de base de datos.
    El módulo <code class="module"><a href="../mod/mod_authn_dbm.html">mod_authn_dbm</a></code> proporciona la directiva <code class="directive"><a href="../mod/mod_authn_dbm.html#authdbmuserfile">AuthDBMUserFile</a></code>. Estos ficheros pueden ser creados y
    manipulados con el programa <code class="program"><a href="../programs/dbmmanage.html">dbmmanage</a></code> y <code class="program"><a href="../programs/htdbm.html">htdbm</a></code>. 
    Muchos otros métodos de autenticación así como otras opciones, están disponibles en 
    módulos de terceros 
    <a href="http://modules.apache.org/">Base de datos de Módulos disponibles</a>.</p>

    <p>Finalmente, la directiva <code class="directive"><a href="../mod/mod_authz_core.html#require">Require</a></code>
    proporciona la parte del proceso de autorización estableciendo el o los
    usuarios que se les está permitido acceder a una región del servidor.
    En la próxima sección, discutiremos las diferentes vías de utilizar la 
    directiva <code class="directive"><a href="../mod/mod_authz_core.html#require">Require</a></code>.</p>
</div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="lettingmorethanonepersonin" id="lettingmorethanonepersonin">Dejar que más de una persona 
	entre</a></h2>
    <p>Las directivas mencionadas arriba sólo permiten a una persona 
    (especialmente con un usuario que en ej ejemplo es <code>rbowen</code>) 
    en el directorio. En la mayoría de los casos, se querrá permitir el acceso
    a más de una persona. Aquí es donde la directiva 
    <code class="directive"><a href="../mod/mod_authz_groupfile.html#authgroupfile">AuthGroupFile</a></code> entra en juego.</p>

    <p>Si lo que se desea es permitir a más de una persona el acceso, necesitarás
     crear un archivo de grupo que asocie los nombres de grupos con el de personas
     para permitirles el acceso. El formato de este fichero es bastante sencillo, 
     y puedes crearlo con tu editor de texto favorito. El contenido del fichero 
     se parecerá a:</p>

   <div class="example"><p><code>
     GroupName: rbowen dpitts sungo rshersey
   </code></p></div>

    <p>Básicamente eso es la lista de miembros los cuales están en un mismo fichero
     de grupo en una sola linea separados por espacios.</p>

    <p>Para añadir un usuario a tu fichero de contraseñas existente teclee:</p>

    <div class="example"><p><code>
      htpasswd /usr/local/apache/passwd/passwords dpitts
    </code></p></div>

    <p>Te responderá lo mismo que anteriormente, pero se añadirá al fichero 
    	existente en vez de crear uno nuevo. (Es decir el flag <code>-c</code> será 
    	el que haga que se genere un nuevo 
    fichero de contraseñas).</p>

    <p>Ahora, tendrá que modificar su fichero <code>.htaccess</code> para que sea 
    parecido a lo siguiente:</p>

    <pre class="prettyprint lang-config">AuthType Basic
AuthName "By Invitation Only"
# Optional line:
AuthBasicProvider file
AuthUserFile "/usr/local/apache/passwd/passwords"
AuthGroupFile "/usr/local/apache/passwd/groups"
Require group GroupName</pre>


    <p>Ahora, cualquiera que esté listado en el grupo <code>GroupName</code>,
    y tiene una entrada en el fichero de <code>contraseñas</code>, se les 
    permitirá el acceso, si introducen su contraseña correctamente.</p>

    <p>Hay otra manera de dejar entrar a varios usuarios, que es menos específica.
    En lugar de crear un archivo de grupo, sólo puede utilizar la siguiente 
    directiva:</p>

    <pre class="prettyprint lang-config">Require valid-user</pre>


    <p>Usando ésto en vez de la línea <code>Require user rbowen</code>
     permitirá a cualquier persona acceder, la cuál aparece en el archivo de 
     contraseñas, y que introduzca correctamente su contraseña. Incluso puede 
     emular el comportamiento del grupo aquí, sólo manteniendo un fichero de 
     contraseñas independiente para cada grupo. La ventaja de este enfoque es 
     que Apache sólo tiene que comprobar un archivo, en lugar de dos. La desventaja 
     es que se tiene que mantener un montón de ficheros de contraseña de grupo, y 
     recuerde hacer referencia al fichero correcto en la directiva
    <code class="directive"><a href="../mod/mod_authn_file.html#authuserfile">AuthUserFile</a></code>.</p>
</div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="possibleproblems" id="possibleproblems">Posibles Problemas</a></h2>
    <p>Debido a la forma en que se especifica la autenticación básica,
    su nombre de usuario y la contraseña deben ser verificados cada vez 
    que se solicita un documento desde el servidor. Esto es, incluso si&nbsp;
    se&nbsp; vuelve a cargar la misma página, y para cada imagen de la página (si
&nbsp;&nbsp;&nbsp;&nbsp;provienen de un directorio protegido). Como se puede imaginar, esto
&nbsp;&nbsp;&nbsp;&nbsp;ralentiza las cosas un poco. La cantidad que ralentiza las cosas es 
    proporcional al tamaño del archivo de contraseñas, porque tiene que 
    abrir ese archivo, recorrer&nbsp;lista de usuarios hasta que llega a su nombre.
    Y tiene que hacer esto cada vez que se carga una página.</p>

    <p>Una consecuencia de esto, es que hay un limite práctico de cuantos 
    usuarios puedes introducir en el fichero de contraseñas. Este límite
    variará dependiendo de la máquina en la que tengas el servidor,
    pero puedes notar ralentizaciones en cuanto se metan cientos de entradas,
    y por lo tanto consideraremos entonces otro método de autenticación
    en ese momento.
	</p>
</div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="dbmdbd" id="dbmdbd">Método alternativo de almacenamiento de las 
	contraseñas</a></h2>

    <p>Debido a que el almacenamiento de las contraseñas en texto plano tiene 
    	el problema mencionado anteriormente, puede que se prefiera guardar 
    	las contraseñas en otro lugar como por ejemplo una base de datos.
    	</p>

    <p>Los módulos <code class="module"><a href="../mod/mod_authn_dbm.html">mod_authn_dbm</a></code> y <code class="module"><a href="../mod/mod_authn_dbd.html">mod_authn_dbd</a></code> son
    dos módulos que hacen esto posible. En vez de seleccionar la directiva de fichero
    <code><code class="directive"><a href="../mod/mod_auth_basic.html#authbasicprovider">AuthBasicProvider</a></code> </code>, en su lugar
    se puede elegir <code>dbm</code> o <code>dbd</code> como formato de almacenamiento.</p>

    <p>Para seleccionar los ficheros de tipo dbm en vez de texto plano, podremos hacer algo parecido a lo siguiente:</p>

    <pre class="prettyprint lang-config">&lt;Directory "/www/docs/private"&gt;
    AuthName "Private"
    AuthType Basic
    AuthBasicProvider dbm
    AuthDBMUserFile "/www/passwords/passwd.dbm"
    Require valid-user
&lt;/Directory&gt;</pre>


    <p>Hay otras opciones disponibles. Consulta la documentación de
    <code class="module"><a href="../mod/mod_authn_dbm.html">mod_authn_dbm</a></code> para más detalles.</p>
</div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="multprovider" id="multprovider">Uso de múltiples proveedores</a></h2>

    <p>Con la introducción de la nueva autenticación basada en un proveedor y
     una arquitectura de autorización, ya no estaremos restringidos a un único
     método de autenticación o autorización. De hecho, cualquier número de 
     los proveedores pueden ser mezclados y emparejados para ofrecerle 
     exactamente el esquema que se adapte a sus necesidades. 
     En el siguiente ejemplo, veremos como ambos proveedores tanto el fichero 
     como el LDAP son usados en la autenticación:
     </p>

    <pre class="prettyprint lang-config">&lt;Directory "/www/docs/private"&gt;
    AuthName "Private"
    AuthType Basic
    AuthBasicProvider file ldap
    AuthUserFile "/usr/local/apache/passwd/passwords"
    AuthLDAPURL ldap://ldaphost/o=yourorg
    Require valid-user
&lt;/Directory&gt;</pre>


    <p>En este ejemplo el fichero, que actúa como proveedor, intentará autenticar 
    	primero al usuario. Si no puede autenticar al usuario, el proveedor del LDAP
    	será llamado para que realice la autenticación.
    	Esto permite al ámbito de autenticación ser amplio, si su organización 
    	implementa más de un tipo de almacén de autenticación. 
    	Otros escenarios de autenticación y autorización pueden incluir la 
    	mezcla de un tipo de autenticación con un tipo diferente de autorización.
    	Por ejemplo, autenticar contra un fichero de contraseñas pero autorizando
    	dicho acceso mediante el directorio del LDAP.</p>

    <p>Así como múltiples métodos y proveedores de autenticación pueden 
    	ser implementados, también pueden usarse múltiples formas de 
    	autorización.
    	En este ejemplo ambos ficheros de autorización de grupo así como 
    	autorización de grupo mediante LDAP va a ser usado:
    </p>

    <pre class="prettyprint lang-config">&lt;Directory "/www/docs/private"&gt;
    AuthName "Private"
    AuthType Basic
    AuthBasicProvider file
    AuthUserFile "/usr/local/apache/passwd/passwords"
    AuthLDAPURL ldap://ldaphost/o=yourorg
    AuthGroupFile "/usr/local/apache/passwd/groups"
    Require group GroupName
    Require ldap-group cn=mygroup,o=yourorg
&lt;/Directory&gt;</pre>


    <p>Para llevar la autorización un poco más lejos, las directivas 
    	de autorización de contenedores tales como
    <code class="directive"><a href="../mod/mod_authz_core.html#requireall">&lt;RequireAll&gt;</a></code>
    and
    <code class="directive"><a href="../mod/mod_authz_core.html#requireany">&lt;RequireAny&gt;</a></code>
    nos permiten aplicar una lógica de en qué orden se manejará la autorización dependiendo
    de la configuración y controlada a través de ella.
    Mire también <a href="../mod/mod_authz_core.html#logic">Contenedores de
    Autorización</a> para ejemplos de cómo pueden ser aplicados.</p>

</div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="beyond" id="beyond">Más allá de la Autorización</a></h2>

    <p>El modo en que la autorización puede ser aplicada es ahora mucho más flexible
    	que us solo chequeo contra un almacén de datos (contraseñas). Ordenando la 
    	lógica y escoger la forma en que la autorización es realizada, ahora es posible 
    </p>

    <h3><a name="authandororder" id="authandororder">Aplicando la lógica y ordenación</a></h3>
        <p>Controlar el cómo y en qué orden se va a aplicar la autorización ha 
        	sido un misterio en el pasado. En Apache 2.2 un proveedor del 
        	mecanismo de autenticación fue introducido para disociar el proceso actual
        	de autenticación y soportar funcionalidad.
        	Uno de los beneficios secundarios fue que los proveedores de autenticación
        	podían ser configurados y llamados en un orden especifico que no dependieran
        	en el orden de carga del propio modulo. 
        	Este proveedor de dicho mecanismo, ha sido introducido en la autorización
        	también. Lo que esto significa es que la directiva 
        	<code class="directive"><a href="../mod/mod_authz_core.html#require">Require</a></code> 
        	no sólo especifica que método de autorización deberá ser usado, si no
        	también especifica el orden en que van a ser llamados. Múltiples
        	métodos de autorización son llamados en el mismo orden en que la directiva
            <code class="directive"><a href="../mod/mod_authz_core.html#require">Require</a></code> aparece en la
            configuración.
        </p>

        <p>
        	Con la Introducción del contenedor de directivas de autorización tales como
	        <code class="directive"><a href="../mod/mod_authz_core.html#requireall">&lt;RequireAll&gt;</a></code>
	        y
	        <code class="directive"><a href="../mod/mod_authz_core.html#requireany">&lt;RequireAny&gt;</a></code>,
	        La configuración también tiene control sobre cuándo se llaman a los métodos
	        de autorización y qué criterios determinan cuándo se concede el acceso.
	        Vease
	        <a href="../mod/mod_authz_core.html#logic">Contenedores de autorización</a>
	        Para un ejemplo de cómo pueden ser utilizados para expresar una lógica 
	        más compleja de autorización.
	    </p>

        <p>
        	Por defecto todas las directivas 
        	<code class="directive"><a href="../mod/mod_authz_core.html#require">Require</a></code>
       		son manejadas como si estuvieran contenidas en una directiva
       		<code class="directive"><a href="../mod/mod_authz_core.html#requireany">&lt;RequireAny&gt;</a></code>.
       		En otras palabras, Si alguno de los métodos de autorización 
       		especificados tiene éxito, se concede la autorización.
       	</p>

    

    <h3><a name="reqaccessctrl" id="reqaccessctrl">Uso de los proveedores de autorización para 
    	el control de acceso</a></h3>

    	<p>
    		La autenticación de nombre de usuario y contraseña es sólo parte
    		de toda la historia que conlleva el proceso. Frecuentemente quiere
    		dar acceso a la gente en base a algo más que lo que son.
    		Algo como de donde vienen.
    	</p>

        <p>
        	Los proveedores de autorización <code>all</code>,
        	<code>env</code>, <code>host</code> y <code>ip</code>
        	te permiten denegar o permitir el acceso basándose en otros
        	criterios como el nombre de la máquina o la IP de la máquina que
        	realiza la consulta para un documento.
        </p>

        <p>
        	El uso de estos proveedores se especifica a través de la directiva
        	<code class="directive"><a href="../mod/mod_authz_core.html#require">Require</a></code>.
        	La directiva registra los proveedores de autorización que serán llamados
        	durante la solicitud de la fase del proceso de autorización. Por ejemplo:
        </p>

        <pre class="prettyprint lang-config">Require ip <var>address</var>
        </pre>


        <p>
        	Donde <var>address</var> es una dirección IP (o una dirección IP parcial) 
        	o bien:
        </p>

        <pre class="prettyprint lang-config">Require host <var>domain_name</var>
        </pre>


        <p>
        	Donde <var>domain_name</var> es el nombre completamente cualificado de un nombre 
	        de dominio (FQDN) (o un nombre parcial del dominio);
	        puede proporcionar múltiples direcciones o nombres de dominio, si se desea.
        </p>

        <p>
        	Por ejemplo, si alguien envía spam a su tablón de mensajes y desea
        	mantenerlos alejados, podría hacer lo siguiente:</p>

        <pre class="prettyprint lang-config">&lt;RequireAll&gt;
    Require all granted
    Require not ip 10.252.46.165
&lt;/RequireAll&gt;</pre>


        <p>
        	Visitantes que vengan desde esa IP no serán capaces de ver el contenido
        	que cubre esta directiva. Si, en cambio, lo que se tiene es el nombre de
        	la máquina, en vez de la dirección IP, podría usar:
        </p>

        <pre class="prettyprint lang-config">&lt;RequireAll&gt;
    Require all granted
    Require not host host.example.com
&lt;/RequireAll&gt;</pre>


        <p>
        	Y, si lo que se quiere es bloquear el acceso desde un determinado dominio
        	(bloquear el acceso desde el dominio entero), puede especificar parte 
        	de la dirección o del propio dominio a bloquear:
        </p>

        <pre class="prettyprint lang-config">&lt;RequireAll&gt;
    Require all granted
    Require not ip 192.168.205
    Require not host phishers.example.com moreidiots.example
    Require not host ke
&lt;/RequireAll&gt;</pre>


        <p>
        	Usando <code class="directive"><a href="../mod/mod_authz_core.html#requireall">&lt;RequireAll&gt;</a></code>
	        con múltiples directivas <code class="directive"><a href="../mod/mod_authz_core.html#require">&lt;Require&gt;</a></code>, cada una negada con un <code>not</code>,
	        Sólo permitirá el acceso, si todas las condiciones negadas son verdaderas.
	        En otras palabras, el acceso será bloqueado, si cualquiera de las condiciones
	        negadas fallara.
        </p>

    

    <h3><a name="filesystem" id="filesystem">Compatibilidad de Control de Acceso con versiones 
    	anteriores </a></h3>

        <p>
        	Uno de los efectos secundarios de adoptar proveedores basados en 
        	mecanismos de autenticación es que las directivas anteriores
	        <code class="directive"><a href="../mod/mod_access_compat.html#order">Order</a></code>,
	        <code class="directive"><a href="../mod/mod_access_compat.html#allow">Allow</a></code>,
	        <code class="directive"><a href="../mod/mod_access_compat.html#deny">Deny</a></code> y
        	<code class="directive"><a href="../mod/mod_access_compat.html#satisfy">Satisfy</a></code> ya no son necesarias.
        	Sin embargo, para proporcionar compatibilidad con configuraciones antiguas,
        	estas directivas se han movido al módulo <code class="module"><a href="../mod/mod_access_compat.html">mod_access_compat</a></code>.
        </p>

        <div class="warning"><h3>Nota:</h3>
	        <p>
	        	Las directivas proporcionadas por <code class="module"><a href="../mod/mod_access_compat.html">mod_access_compat</a></code> 
	        	han quedado obsoletas por <code class="module"><a href="../mod/mod_authz_host.html">mod_authz_host</a></code>. Mezclar 
	        	directivas antiguas como
	        	<code class="directive"><a href="../mod/mod_access_compat.html#order">Order</a></code>, 
	            <code class="directive"><a href="../mod/mod_access_compat.html#allow">Allow</a></code> ó 
	            <code class="directive"><a href="../mod/mod_access_compat.html#deny">Deny</a></code> con las nuevas 
	            como 
	            <code class="directive"><a href="../mod/mod_authz_core.html#require">Require</a></code> 
	            es técnicamente posible pero desaconsejable. El módulo 
	            <code class="module"><a href="../mod/mod_access_compat.html">mod_access_compat</a></code> se creó para soportar configuraciones
	            que contuvieran sólo directivas antiguas para facilitar la actualización
	            a la versión 2.4.
	            Por favor revise la documentación de 
	            <a href="../upgrading.html">actualización</a> para más información al
	            respecto.
	        </p>
	    </div>
	

	</div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="socache" id="socache">Cache de Autenticación</a></h2>
	<p>
		Puede haber momentos en que la autenticación ponga una carga 
		inaceptable en el proveedor (de autenticación) o en tu red.
		Esto suele afectar a los usuarios de <code class="module"><a href="../mod/mod_authn_dbd.html">mod_authn_dbd</a></code> 
		(u otros proveedores de terceros/personalizados).
		Para lidiar con este problema, HTTPD 2.3/2.4 introduce un nuevo proveedor
		de caché  <code class="module"><a href="../mod/mod_authn_socache.html">mod_authn_socache</a></code> para cachear las credenciales 
		y reducir la carga en el proveedor(es) original.
	</p>
    <p>
    	Esto puede ofrecer un aumento de rendimiento sustancial para algunos usuarios.
    </p>
</div><div class="top"><a href="#page-header"><img alt="top" src="../images/up.gif" /></a></div>
<div class="section">
<h2><a name="moreinformation" id="moreinformation">Más información</a></h2>

    <p>
    	También debería leer la documentación para
    	<code class="module"><a href="../mod/mod_auth_basic.html">mod_auth_basic</a></code> y <code class="module"><a href="../mod/mod_authz_host.html">mod_authz_host</a></code>
    	la cuál contiene más información de como funciona todo esto.
    	La directiva <code class="directive"><a href="../mod/mod_authn_core.html#authnprovideralias">&lt;AuthnProviderAlias&gt;</a></code> puede también ayudar 
	    a la hora de simplificar ciertas configuraciones de autenticación.
	</p>

    <p>
    	Los diferentes algoritmos de cifrado que están soportados por Apache
    	para la autenticación se explican en
    	<a href="../misc/password_encryptions.html">Cifrado de Contraseñas</a>.
    </p>

    <p>
    	Y tal vez quiera ojear la documentación de "how to"  
    	<a href="access.html">Control de Acceso</a>  donde se mencionan temas 
    	relacionados.</p>

</div></div>
<div class="bottomlang">
<p><span>Idiomas disponibles: </span><a href="../en/howto/auth.html" hreflang="en" rel="alternate" title="English">&nbsp;en&nbsp;</a> |
<a href="../es/howto/auth.html" title="Español">&nbsp;es&nbsp;</a> |
<a href="../fr/howto/auth.html" hreflang="fr" rel="alternate" title="Français">&nbsp;fr&nbsp;</a> |
<a href="../ja/howto/auth.html" hreflang="ja" rel="alternate" title="Japanese">&nbsp;ja&nbsp;</a> |
<a href="../ko/howto/auth.html" hreflang="ko" rel="alternate" title="Korean">&nbsp;ko&nbsp;</a> |
<a href="../tr/howto/auth.html" hreflang="tr" rel="alternate" title="Türkçe">&nbsp;tr&nbsp;</a></p>
</div><div class="top"><a href="#page-header"><img src="../images/up.gif" alt="top" /></a></div><div class="section"><h2><a id="comments_section" name="comments_section">Comentarios</a></h2><div class="warning"><strong>Notice:</strong><br />This is not a Q&amp;A section. Comments placed here should be pointed towards suggestions on improving the documentation or server, and may be removed again by our moderators if they are either implemented or considered invalid/off-topic. Questions on how to manage the Apache HTTP Server should be directed at either our IRC channel, #httpd, on Freenode, or sent to our <a href="http://httpd.apache.org/lists.html">mailing lists</a>.</div>
<script type="text/javascript"><!--//--><![CDATA[//><!--
var comments_shortname = 'httpd';
var comments_identifier = 'http://httpd.apache.org/docs/2.4/howto/auth.html';
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