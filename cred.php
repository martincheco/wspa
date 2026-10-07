<?php
session_start();
session_destroy();
?>
<FORM action=login.php method=POST>
<INPUT type=TEXT tabindex=1 size=8 id="usename" name=usename placeholder=Username>
<INPUT type=PASSWORD tabindex=2 size=8 name=drowssap placeholder=Password>
<INPUT type=SUBMIT tabindex=3 name=go value=">>">
</FORM>
<script>
		document.getElementById("usename").focus();
</script>
<?php exit; ?>