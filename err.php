<?
require('globals.php');
require('auth.php');
require('head.php');
if (file_exists($userdir.$user.'/gdl.log')){$debug=@file_get_contents($userdir.$user.'/gdl.log',false,null,-10000);}else{$debug="Can't get GDL log :(";}

if (empty($debug)){$debug=file_get_contents($userdir.$user.'/gdl.log');}

?>

<HTML><HEAD></HEAD><BODY style="font-family:monospace;">
<div class=fill>
<TABLE><TR><TD><TABLE><TR><TD>
<TEXTAREA readonly tabindex=-1 id="filldebug" NAME="debug" placeholder="nothing" rows=30 cols=50>
<?echo $debug;?>
</TEXTAREA>
	
	</TR></TABLE></TR></TABLE>
</div>

<script>
    var textArea = document.getElementById("filldebug");
	textArea.scrollTop = textArea.scrollHeight;

</script>
</BODY></HTML>
<?exit;?>
