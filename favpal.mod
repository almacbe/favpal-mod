############################################################## 
## MOD Title: FavPal Mod for PhpBB
## MOD Author: almacbe < almacbe@gmail.com > (Alfonso Machado) http://alfonsomachado.com 
## MOD Description: This mod will add a feature for thanking the poster for his/her post using FavPal.
##					
## MOD Version: 0.0.1
## 
## Installation Level: Intermediate 
## Installation Time: 25 Minutes
## Files To Edit: 11
##                admin/admin_forums.php,
##								modcp.php,
##                posting.php,
##                viewtopic.php,
##                includes/constants.php,
##                includes/functions.php,
##								includes/functions_post.php,
##                langugage/lang_english/lang_main.php,
##                langugage/lang_english/lang_admin.php,
##                templates/subSilver/viewtopic_body.tpl,
##                templates/subSilver/admin/forum_edit_body.tpl
## Included Files: 1
##								templates/subSilver/images/lang_english/thanks.gif	
##
## License: http://opensource.org/licenses/gpl-license.php GNU General Public License v2
##############################################################
## MOD History: 
##   2005-02-25 - Version 0.0.1 
##      	- First Release
############################################################## 
## Before Adding This MOD To Your Forum, You Should Back Up All Files Related To This MOD 
##############################################################
##
#
#-----[ COPY ]------------------------------------------
#
copy thanks.gif to templates/subSilver/images/lang_english/thanks.gif
#
#-----[ SQL ]------------------------------------------
#
CREATE TABLE `phpbb_favpal_thanks` (
`topic_id` MEDIUMINT(8) NOT NULL,
`post_id` MEDIUMINT(8) NOT NULL,
`user_id` MEDIUMINT(8) NOT NULL,
`thanks_time` INT(11) NOT NULL
);

ALTER TABLE `phpbb_users` 
ADD `favpal_id` INT,
ADD `favpal_user` VARCHAR( 255 ),
ADD `favpal_password` VARCHAR( 255 );

# 
#-----[ OPEN ]------------------------------------------ 
#
modcp.php

# 
#-----[ FIND ]------------------------------------------ 
#
			$sql = "DELETE 
				FROM " . TOPICS_TABLE . " 
				WHERE topic_id IN ($topic_id_sql) 
					OR topic_moved_id IN ($topic_id_sql)";
			if ( !$db->sql_query($sql, BEGIN_TRANSACTION) )
			{
				message_die(GENERAL_ERROR, 'Could not delete topics', '', __LINE__, __FILE__, $sql);
			}

# 
#-----[ BEFORE, ADD ]------------------------------------------ 
#
			$sql = "DELETE FROM " . THANKS_TABLE . "
					WHERE topic_id IN ($topic_id_sql)";
			if ( !$db->sql_query($sql, BEGIN_TRANSACTION) )
			{
							message_die(GENERAL_ERROR, 'Error in deleting Thanks post Information', '', __LINE__, __FILE__, $sql);
			}

#
#-----[ OPEN ]------------------------------------------
#
viewtopic.php

#
#-----[ FIND ]---------------------------------
#
$reply_topic_url = append_sid("posting.$phpEx?mode=reply&amp;" . POST_TOPIC_URL . "=$topic_id");

#
#-----[ AFTER, ADD ]---------------------------------
#
// Begin FavPal Mod
$thank_topic_url = append_sid("posting.$phpEx?mode=thank&amp;" . POST_TOPIC_URL . "=$topic_id");
// End FavPal Mod

#
#-----[ FIND ]---------------------------------
#
$post_img = ( $forum_topic_data['forum_status'] == FORUM_LOCKED ) ? $images['post_locked'] : $images['post_new'];
$post_alt = ( $forum_topic_data['forum_status'] == FORUM_LOCKED ) ? $lang['Forum_locked'] : $lang['Post_new_topic'];

#
#-----[ AFTER, ADD ]---------------------------------
#
// Begin FavPal Mod
$thank_img = $images['thanks'];
$favpal_img = '';
$thank_alt = $lang['thanks_alt'];
// End FavPal Mod

#
#-----[ FIND ]---------------------------------
#
# the whole line is: $pagination = ( $highlight != '' ) ? generate_pagination("viewtopic.$phpEx?" . POST_TOPIC_URL . "=$topic_id&amp;postdays=$post_days&amp;postorder=$post_order&amp;highlight=$highlight", $total_replies, $board_config['posts_per_page'], $start) : generate_pagination("viewtopic.$phpEx?" . POST_TOPIC_URL . "=$topic_id&amp;postdays=$post_days&amp;postorder=$post_order", $total_replies, $board_config['posts_per_page'], $start);
#
$pagination =

#
#-----[ AFTER, ADD ]---------------------------------
#
// Begin FavPal Mod
$current_page = get_page($total_replies, $board_config['posts_per_page'], $start);
// End FavPal Mod

#
#-----[ FIND ]---------------------------------
#
$sql = "UPDATE " . TOPICS_TABLE . "
	SET topic_views = topic_views + 1
	WHERE topic_id = $topic_id";
if ( !$db->sql_query($sql) )
{
	message_die(GENERAL_ERROR, "Could not update topic views.", '', __LINE__, __FILE__, $sql);
}

#
#-----[ AFTER, ADD ]---------------------------------
#

//Begin FavPal Mod
$sql = "SELECT favpal_id
		FROM " . USERS_TABLE . "
		WHERE user_id = $userdata[user_id]";

if ( !($result = $db->sql_query($sql)) )
{
	message_die(GENERAL_ERROR, "Could not obtain user information", '', __LINE__, __FILE__, $sql);
}
$favpal_id = $db->sql_fetchrowset($result);

$favpal_info = false;
if( $favpal_id[0]['favpal_id'] )
{
	$favpal_info = true;
}

//End FavPal Mod

#
#-----[ FIND ]---------------------------------
#
	else
	{
		$l_edited_by = '';
	}

#
#-----[ AFTER, ADD ]---------------------------------
#

	// Begin FavPal Mod
	if( $favpal_info )
	{
		// Select Format for the date
		$timeformat = "d-m, G:i";

		$sql = "SELECT u.user_id, u.username, t.thanks_time
			 FROM " . THANKS_TABLE . " t, " . USERS_TABLE . " u
			 WHERE topic_id = $topic_id
			 AND post_id = " . $postrow[$i]['post_id'] .
			 " AND t.user_id = u.user_id";

		if ( !($result = $db->sql_query($sql)) )
		{
			message_die(GENERAL_ERROR, "Could not obtain thanks information", '', __LINE__, __FILE__, $sql);
		}

		$total_thank = $db->sql_numrows($result);
		if( $total_thank > 0 ){
			$thanks = "";		
			$thanksrow = array();
			$thanksrow = $db->sql_fetchrowset($result);

			for($k = 0; $k < $total_thank; $k++)
			{
				$topic_thanks = $db->sql_fetchrow($result);
				$thanker_id[$k] = $thanksrow[$k]['user_id'];
				$thanker_name[$k] = $thanksrow[$k]['username'];
				$thanks_date[$k] = $thanksrow[$k]['thanks_time'];

				// Get thanks date
				$thanks_date[$k] = create_date($timeformat, $thanks_date[$k], $board_config['board_timezone']);

				// Make thanker profile link
				$thanker_profile[$k] = append_sid("profile.$phpEx?mode=viewprofile&amp;" . POST_USERS_URL . "=$thanker_id[$k]");   
				$thanks .= '<a href="' .$thanker_profile[$k] . '">' . $thanker_name[$k] . '</a>(' . $thanks_date[$k] . '), ';

				if ($userdata['user_id'] == $thanksrow[$k]['user_id'])
				{
					$thanked = TRUE;
				}
			}

			$sql = "SELECT u.topic_poster, t.user_id, t.username
					FROM " . TOPICS_TABLE . " u, " . USERS_TABLE . " t
					WHERE topic_id = $topic_id
					AND u.topic_poster = t.user_id";

			if ( !($result = $db->sql_query($sql)) )
			{
				message_die(GENERAL_ERROR, "Could not obtain user information", '', __LINE__, __FILE__, $sql);
			}

			if( !($autor = $db->sql_fetchrowset($result)) )
			{
				message_die(GENERAL_ERROR, "Could not obtain user information", '', __LINE__, __FILE__, $sql);
			}	

			$autor_name = $autor[0]['username'];
			$thanks .= "".$lang['thanks_to']." $autor_name ".$lang['thanks_end']."";
		}

		$favpal_img = '<a href="' . $thank_topic_url . "&amp;p=" . $postrow[$i]['post_id'] . "&amp;u=" . $postrow[$i]['user_id'] . '"><img src="' .  $thank_img . '" alt="' . $thank_alt . '" title="' . "Thanks" . '" border="0" /></a>';
	
	}
	//End FavPal Mod

#
#-----[ FIND ]---------------------------------
#

		'MINI_POST_IMG' => $mini_post_img,
		'PROFILE_IMG' => $profile_img,

#
#-----[ AFTER, ADD ]---------------------------------
#

//FavPal
'FAVPAL_IMG' => $favpal_img,

#
#-----[ FIND ]---------------------------------
#
		'U_POST_ID' => $postrow[$i]['post_id'])
	);

#
#-----[ AFTER, ADD ]---------------------------------
#
	// Begin FavPal Mod
	if( $favpal_info && ($total_thank > 0) )
	{
		$template->assign_block_vars('postrow.thanks', array(
		'THANKFUL' => $lang['thankful'],
		'THANKED' => $lang['thanked'],
		'HIDE' => $lang['hide'],
		'THANKS_TOTAL' => $total_thank,
		'THANKS' => $thanks
		)
		);

	}
	// End FavPal Mod

#
#-----[ OPEN ]---------------------------------
#
posting.php

#
#-----[ FIND ]---------------------------------
#
	case 'topicreview':
		$is_auth_type = 'auth_read';
		break;

#
#-----[ AFTER, ADD ]---------------------------------
#
	case 'thank':
		$is_auth_type = 'auth_read';
		break;

#
#-----[ FIND ]---------------------------------
#
	case 'reply':
	case 'vote':

#-----[ BEFORE, ADD ]---------------------------------
	case 'thank':			ESTO ESTA CAMBIADO POR MI PERO NO TENGO CLARO PARA QUE...

#
#-----[ FIND ]---------------------------------
#
	else if ( $mode != 'newtopic' && $post_info['topic_status'] == TOPIC_LOCKED && !$is_auth['auth_mod']) 

#
#-----[ IN-LINE FIND ]---------------------------------
#
 $mode != 'newtopic'

#
#-----[ IN-LINE AFTER, ADD ]---------------------------------
#
  &&  $mode != 'thank'

#
#-----[ FIND ]---------------------------------
#
		case 'reply':
		case 'topicreview':

#
#-----[ BEFORE, ADD ]---------------------------------
#
		case 'thank':

#
#-----[ FIND ]---------------------------------
#
else if ( $mode == 'vote' )
{

#
#-----[ BEFORE, ADD ]---------------------------------
#

else if ( $mode == 'thank' )
{	//Begin FavPal Mod
	$topic_id = intval($HTTP_GET_VARS[POST_TOPIC_URL]);
	$post_id = intval($HTTP_GET_VARS[POST_POST_URL]);
	$post_user_id = intval($HTTP_GET_VARS['u']);
		if ( !($userdata['session_logged_in']) )
		{
			$message = $lang['thanks_not_logged'];
			$message .=  '<br /><br />' . sprintf($lang['Click_return_topic'], '<a href="' . append_sid("viewtopic.$phpEx?" . POST_TOPIC_URL . "=$topic_id") . '">', '</a>');
			message_die(GENERAL_MESSAGE, $message);
		}
		if ( empty($topic_id) )
		{
			message_die(GENERAL_MESSAGE, 'No topic Selected');
		}
		if ( empty($post_id) )
		{
			message_die(GENERAL_MESSAGE, 'No post Selected');
		}

		$userid = $userdata['user_id'];
		$thanks_date = time();

		// Check if user is the topic starter
		$sql = "SELECT `poster_id`
				FROM " . POSTS_TABLE . " 
				WHERE topic_id = $topic_id
				AND post_id = " . $post_id .
				" AND poster_id = $userid";
		if ( !($result = $db->sql_query($sql)) )
		{
			message_die(GENERAL_ERROR, "Couldn't check for topic starter", '', __LINE__, __FILE__, $sql);
					
		}

		if ( ($topic_starter_check = $db->sql_fetchrow($result)) )
		{
			$message = $lang['t_starter'];
			$message .=  '<br /><br />' . sprintf($lang['Click_return_topic'], '<a href="' . append_sid("viewtopic.$phpEx?" . POST_TOPIC_URL . "=$topic_id") . '">', '</a>');
			message_die(GENERAL_MESSAGE, $message);
		}

		// Check if user had thanked before
		$sql = "SELECT `topic_id`
				FROM " . THANKS_TABLE . " 
				WHERE topic_id = $topic_id
				AND post_id = " . $post_id .
				" AND user_id = $userid";
		if ( !($result = $db->sql_query($sql)) )
		{
			message_die(GENERAL_ERROR, "Couldn't check for previous thanks", '', __LINE__, __FILE__, $sql);
					
		}
		
		if ( !($thankfull_check = $db->sql_fetchrow($result)) )
		{
			
			//Comprobamos si tiene cuenta FAVPAL la persona a la que thankeamos
			
			 $sql = "SELECT `favpal_id`, `favpal_password`, `favpal_user` 
					FROM " . USERS_TABLE . " 
					WHERE user_id = $post_user_id";

			if ( !($result = $db->sql_query($sql)) )
			{
				message_die(GENERAL_ERROR, "Problemas accediendo a FavPal", '', __LINE__, __FILE__, $sql);
			}
			
			$favpal_transfer = false;	// control de transferencia
			
			if ( !($favpal_check = $db->sql_fetchrow($result)) )
			{
				message_die(GENERAL_ERROR, "Problemas accediendo a la informacion de FavPal del usuario", '', __LINE__, __FILE__, $sql);
			}
			
			if ( empty($favpal_check['favpal_id']) )
			{	//No tiene cuenta de FavPal, la creamos

				//Crear la transferencia
				$sql = "SELECT `favpal_id`, `favpal_password`
						FROM " . USERS_TABLE . "
						WHERE user_id = $userid";
				if ( !($result = $db->sql_query($sql)) )
				{
					message_die(GENERAL_ERROR, "Problemas accediendo a la informacion de FavPal del usuario", '', __LINE__, __FILE__, $sql);
				}

				if ( !($favpal_info = $db->sql_fetchrow($result)) )
				{
					message_die(GENERAL_ERROR, "Problemas accediendo a la informacion de FavPal del usuario", '', __LINE__, __FILE__, $sql);
				}

				$login = "$favpal_info[favpal_id]:$favpal_info[favpal_password]";		//Usuario:contraseña de la persona que va a enviar el fav
				
				srand (time());
				$password = "";
				for ($k = 1; $k <= 10; $k++){
					$password .= rand(0,9);
				}
				$xml = "<abitant><password>$password</password><password_confirmation>$password</password_confirmation></abitant>";
				
				$target = "http://favpal.org/abitants.xml";

				$ch = curl_init();
				curl_setopt($ch, CURLOPT_URL, $target);
				curl_setopt($ch, CURLOPT_USERPWD, $login);
				curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
				curl_setopt ($ch, CURLOPT_HTTPHEADER, Array("Content-Type: text/xml"));
				curl_setopt($ch, CURLOPT_POSTFIELDS, $xml);
				
				$xml = curl_exec($ch);
								
				if( curl_getinfo($ch, CURLINFO_HTTP_CODE) == 201 )
				{
					$items = new SimpleXMLElement($xml);

					$favpal_password = $items->{'crypted-password'};
					$favpal_id = $items->id;
					
					$sql = "UPDATE " . USERS_TABLE . "
							SET favpal_id = $favpal_id, favpal_password = '$favpal_password'
							WHERE user_id = $post_user_id";

					if ( !$db->sql_query($sql) )
					{
						message_die(GENERAL_ERROR, 'Could not update information user', '', __LINE__, __FILE__, $sql);
					}
					else{
						$favpal_transfer = true;
					}
					
				}
				else{
					$message .= $xml;
				}
			}
			else{	//Tiene cuenta de FAVPAL...
				
				//Crear la transferencia
				$sql = "SELECT `favpal_id`, `favpal_password`
						FROM " . USERS_TABLE . "
						WHERE user_id = $userid";
				
				if ( !($result = $db->sql_query($sql)) )
				{
					message_die(GENERAL_ERROR, "Problemas accediendo a la informacion de FavPal del usuario", '', __LINE__, __FILE__, $sql);
				}

				if ( !($favpal_info = $db->sql_fetchrow($result)) )
				{
					message_die(GENERAL_ERROR, "Problemas accediendo a la informacion de FavPal del usuario", '', __LINE__, __FILE__, $sql);
				}
				
				$login = "$favpal_info[favpal_id]:$favpal_info[favpal_password]";		//Usuario:contraseña de la persona que va a enviar el fav

				$xml = "";
				if( empty($favpal_check['favpal_user']) ){
					$xml .= "<transfer><receiver>$favpal_check[favpal_id]</receiver></transfer>";
				}
				else{
					$xml .= "<transfer><receiver>$favpal_check[favpal_user]</receiver></transfer>";
				}
				
				$target = "http://favpal.org/transfers.xml";
				
				$ch = curl_init();
				curl_setopt($ch, CURLOPT_URL, $target);
				curl_setopt($ch, CURLOPT_USERPWD, $login);
				curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
				curl_setopt ($ch, CURLOPT_HTTPHEADER, Array("Content-Type: text/xml"));
				curl_setopt($ch, CURLOPT_POSTFIELDS, $xml);				
				
				$xml = curl_exec($ch);
				
				if( curl_getinfo($ch, CURLINFO_HTTP_CODE) == 201 )
				{
					// Se ha hecho la transferencia
					$favpal_transfer = true;
				}
				else{
					$message .= $xml;
				}
			}
			if($favpal_transfer === true){
				// Insert thanks if he/she hasn't
				$sql = "INSERT INTO " . THANKS_TABLE . " (topic_id, user_id, thanks_time, post_id) 
				VALUES ('" . $topic_id . "', '" . $userid . "', " . $thanks_date . ", '" . $post_id . "') ";
				if ( !($result = $db->sql_query($sql)) )
				{
					message_die(GENERAL_ERROR, "Could not insert thanks information", '', __LINE__, __FILE__, $sql);

				}
				$message = $lang['thanks_add'];
			}
		}
		else
		{
			$message = $lang['thanked_before'];
		}

		$template->assign_vars(array(
			'META' => '<meta http-equiv="refresh" content="3;url=' . append_sid("viewtopic.$phpEx?" . POST_TOPIC_URL . "=$topic_id") . '">')
		);

		$message .=  '<br /><br />' . sprintf($lang['Click_return_topic'], '<a href="' . append_sid("viewtopic.$phpEx?" . POST_TOPIC_URL . "=$topic_id") . '">', '</a>');
		
		message_die(GENERAL_MESSAGE, $message);	
}	//End FavPal Mod

#
#-----[ OPEN ]---------------------------------
#
includes/usercp_registre.php

#
#-----[ FIND ]---------------------------------
#
//
// Let's make sure the user isn't logged in while registering,
// and ensure that they were trying to register a second time
// (Prevents double registrations)
//
if ($mode == 'register' && ($userdata['session_logged_in'] || $username == $userdata['username']))
{
	message_die(GENERAL_MESSAGE, $lang['Username_taken'], '', __LINE__, __FILE__);
}

#
#-----[ BEFORE, ADD ]---------------------------------
#

//Begin FavPal Mod
$sql = "SELECT favpal_id, favpal_user, favpal_password 
		FROM " . USERS_TABLE . " 
		WHERE user_id = $userdata[user_id]";
if (!($result = $db->sql_query($sql)))
{
	message_die(GENERAL_ERROR, 'Fallo en la obtencion de la informacion de FAVPAL en la DB', '', __LINE__, __FILE__, $sql);
}

if ($row = $db->sql_fetchrow($result))
{
	$favpal_id = $row['favpal_id'];
	$favpal_user = $row['favpal_user'];
	
	if( empty($favpal_id) && empty($favpal_user) )
	{
		$favpal_info = "If you have an account at FavPal.org, introduce your username and password";
		$template->assign_block_vars('favpal_edit_profile', array());
		$favpal_oper = "confirm";
	}
	else if( empty($favpal_user) )
	{
		$favpal_info = "Set your FavPal username and password (optional)";
		$template->assign_block_vars('favpal_edit_profile', array());
		$favpal_oper = "create";
	}
	else
	{
		$favpal_info = "Change your FavPal information (optional)";
		$template->assign_block_vars('favpal_no_edit_profile', array());
		$favpal_oper = "confirm";
	}
}
else
{		
	$error = TRUE;
	$error_msg .= ( ( isset($error_msg) ) ? '<br />' : '' ) . "Fallo de FAVPAL, no se ha encontrado info del usuario";
}
$db->sql_freeresult($result);
//End FavPal Mod

#
#-----[ FIND ]---------------------------------
#
	else if ( $user_avatar_local != '' && $board_config['allow_avatar_local'] )
	{
		user_avatar_delete($userdata['user_avatar_type'], $userdata['user_avatar']);
		$avatar_sql = user_avatar_gallery($mode, $error, $error_msg, $user_avatar_local, $user_avatar_category);
	}

#
#-----[ AFTER, ADD ]---------------------------------
#

//Begin FavPal Mod
if( !empty($HTTP_POST_VARS['favpal_user']) )
{
	if( !empty($HTTP_POST_VARS['favpal_password']) )
	{
		if($HTTP_POST_VARS['favpal_oper'] === "confirm")
			{
			$favpal_user = trim($HTTP_POST_VARS['favpal_user']);
			$favpal_password = trim($HTTP_POST_VARS['favpal_password']);

			$login = "$favpal_user:$favpal_password";
			$target = "http://favpal.org/abitants/test_auth.xml";

			$ch = curl_init();
			curl_setopt($ch, CURLOPT_URL, $target);
			curl_setopt($ch, CURLOPT_USERPWD, $login);
			curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);

			$xml = curl_exec($ch);

			if( curl_getinfo($ch, CURLINFO_HTTP_CODE) == 200 )
			{
				$items = new SimpleXMLElement($xml);

				$favpal_user = $items->login;
				$favpal_password = $items->{'crypted-password'};
				$favpal_id = $items->id;
			}
			else
			{
				$error = true;
				$favpal_password = '';
				$error_msg .= ( ( !empty($error_msg) ) ? '<br />' : '' ) . "La informacion de FAVPAL es incorrecta";
			}
		}
		else if($HTTP_POST_VARS['favpal_oper'] === "create")
		{
			$sql = "SELECT `favpal_id`, `favpal_password`
					FROM " . USERS_TABLE . "
					WHERE user_id = $userdata[user_id]";
			if ( !($result = $db->sql_query($sql)) )
			{
				message_die(GENERAL_ERROR, "Problemas accediendo a la informacion de FavPal del usuario", '', __LINE__, __FILE__, $sql);
			}

			if ( !($favpal_information = $db->sql_fetchrow($result)) )
			{
				message_die(GENERAL_ERROR, "Problemas accediendo a la informacion de FavPal del usuario", '', __LINE__, __FILE__, $sql);
			}
			$db->sql_freeresult($result);

			$login = "$favpal_information[favpal_id]:$favpal_information[favpal_password]";		//Usuario:contraseña de la persona que va a enviar el fav

			$target = "http://favpal.org/abitants/$favpal_information[favpal_id].xml";

			$favpal_user = trim($HTTP_POST_VARS['favpal_user']);
			$favpal_newpassword = trim($HTTP_POST_VARS['favpal_password']);
			$xml = "<abitant><login>$favpal_user</login><password>$favpal_newpassword</password><password-confirmation>$favpal_newpassword</password-confirmation></abitant>";

			$ch = curl_init();
			curl_setopt($ch, CURLOPT_URL, $target);
			curl_setopt($ch, CURLOPT_USERPWD, $login);
			curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
			curl_setopt ($ch, CURLOPT_HTTPHEADER, Array("Content-Type: text/xml"));
			curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
			curl_setopt($ch, CURLOPT_POSTFIELDS, $xml);

			$xml = curl_exec($ch);
			if( curl_getinfo($ch, CURLINFO_HTTP_CODE) == 200 )
			{
				$items = new SimpleXMLElement($xml);

				$favpal_user = $items->login;
				$favpal_password = $items->{'crypted-password'};
				$favpal_id = $items->id;
			}
			else
			{
				$error = true;
				$favpal_password = '';
				$error_msg .= ( ( !empty($error_msg) ) ? '<br />' : '' ) . "La informacion de FAVPAL es incorrecta";
			}
		}
	}
	else
	{
		$sql = "SELECT favpal_password FROM " . USERS_TABLE . " WHERE user_id = $userdata[user_id]";
		if (!($result = $db->sql_query($sql)))
		{
			message_die(GENERAL_ERROR, '2. Fallo en la obtencion de la informacion de FAVPAL en la DB', '', __LINE__, __FILE__, $sql);
		}

		if ($row = $db->sql_fetchrow($result))
		{
			$favpal_password = $row['favpal_password'];
		}
		$db->sql_freeresult($result);			
	}
}
//End FavPal Mod

#
#-----[ FIND ]---------------------------------
# This is a partial line, the complete line is much longer
#
			$sql = "UPDATE " . USERS_TABLE . "
				SET " . $username_sql . $passwd_sql . "user_email = '" . str_replace("\'", "''", $email) ."', user_icq = '" . str_replace("\'", "''", $icq) . "',

#
#-----[ IN-LINE FIND ]---------------------------------
#
. "'" . $avatar_sql . "

#
#-----[ AFTER IN-LINE, ADD ]---------------------------------
#
, favpal_id = " . $favpal_id . ", favpal_user = '" . $favpal_user . "', favpal_password = '" . $favpal_password . "'

#
#-----[ FIND ]---------------------------------
#
			$sql = "INSERT INTO " . USERS_TABLE . "	(user_id, username, user_regdate, user_password, user_email, user_icq, user_website, user_occ, user_from, user_interests, user_sig, user_sig_bbcode_uid, user_avatar, user_avatar_type, user_viewemail, user_aim, user_yim, user_msnm, user_attachsig, user_allowsmile, user_allowhtml, user_allowbbcode, user_allow_viewonline, user_notify, user_notify_pm, user_popup_pm, user_timezone, user_dateformat, user_lang, user_style, user_level, user_allow_pm, user_active, user_actkey)
				VALUES ($user_id, '" . str_replace("\'", "''", $username) . "', " . time() . ", '" . str_replace("\'", "''", $new_password) . "', '" . str_replace("\'", "''", $email) . "', '" . str_replace("\'", "''", $icq) . "', '" . str_replace("\'", "''", $website) . "', '" . str_replace("\'", "''", $occupation) . "', '" . str_replace("\'", "''", $location) . "', '" . str_replace("\'", "''", $interests) . "', '" . str_replace("\'", "''", $signature) . "', '$signature_bbcode_uid', $avatar_sql, $viewemail, '" . str_replace("\'", "''", str_replace(' ', '+', $aim)) . "', '" . str_replace("\'", "''", $yim) . "', '" . str_replace("\'", "''", $msn) . "', $attachsig, $allowsmilies, $allowhtml, $allowbbcode, $allowviewonline, $notifyreply, $notifypm, $popup_pm, $user_timezone, '" . str_replace("\'", "''", $user_dateformat) . "', '" . str_replace("\'", "''", $user_lang) . "', $user_style, 0, 1, ";

#
#-----[ REPLACE ]---------------------------------
#

			$sql = "INSERT INTO " . USERS_TABLE . "	(user_id, username, user_regdate, user_password, user_email, user_icq, user_website, user_occ, user_from, user_interests, user_sig, user_sig_bbcode_uid, user_avatar, user_avatar_type, user_viewemail, user_aim, user_yim, user_msnm, user_attachsig, user_allowsmile, user_allowhtml, user_allowbbcode, user_allow_viewonline, user_notify, user_notify_pm, user_popup_pm, user_timezone, user_dateformat, user_lang, user_style, user_level, user_allow_pm, favpal_id, favpal_user, favpal_password, user_active, user_actkey)			
				VALUES ($user_id, '" . str_replace("\'", "''", $username) . "', " . time() . ", '" . str_replace("\'", "''", $new_password) . "', '" . str_replace("\'", "''", $email) . "', '" . str_replace("\'", "''", $icq) . "', '" . str_replace("\'", "''", $website) . "', '" . str_replace("\'", "''", $occupation) . "', '" . str_replace("\'", "''", $location) . "', '" . str_replace("\'", "''", $interests) . "', '" . str_replace("\'", "''", $signature) . "', '$signature_bbcode_uid', $avatar_sql, $viewemail, '" . str_replace("\'", "''", str_replace(' ', '+', $aim)) . "', '" . str_replace("\'", "''", $yim) . "', '" . str_replace("\'", "''", $msn) . "', $attachsig, $allowsmilies, $allowhtml, $allowbbcode, $allowviewonline, $notifyreply, $notifypm, $popup_pm, $user_timezone, '" . str_replace("\'", "''", $user_dateformat) . "', '" . str_replace("\'", "''", $user_lang) . "', $user_style, 0, 1, '$favpal_id', '$favpal_user', '$favpal_password', ";

#
#-----[ FIND ]---------------------------------
#
		'L_PROFILE_INFO_NOTICE' => $lang['Profile_info_warn'],
		'L_EMAIL_ADDRESS' => $lang['Email_address'],

#
#-----[ AFTER, ADD ]---------------------------------
#

//Begin FavPal Mod
'L_FAVPAL_INFO' => "FAVPAL Information",
'L_FAVPAL_INFO_NOTICE' => $favpal_info,
'L_FAVPAL_USER' => "Username",
'L_FAVPAL_PASS' => "Password",
'FAVPAL_USER' => isset($favpal_user) ? $favpal_user : '',
'FAVPAL_PASSWORD' => isset($favpal_password) ? $favpal_password : '',
'FAVPAL_OPER' => $favpal_oper,
//End FavPal Mod

#
#-----[ OPEN ]---------------------------------
#
includes/constants.php

#
#-----[ FIND ]---------------------------------
#
define('SMILIES_TABLE', $table_prefix.'smilies');

#
#-----[ AFTER, ADD ]---------------------------------
#
define('THANKS_TABLE', $table_prefix.'favpal_thanks');

#
#-----[ OPEN ]---------------------------------
#
includes/functions.php

#
#-----[ FIND ]---------------------------------
#
function generate_pagination

#
#-----[ BEFORE, ADD ]---------------------------------
#
function get_page($num_items, $per_page, $start_item)
{

	$total_pages = ceil($num_items/$per_page);

	if ( $total_pages == 1 )
	{
		return '1';
		exit;
	}

	$on_page = floor($start_item / $per_page) + 1;
	$page_string = '';

	for($i = 0; $i < $total_pages + 1; $i++)
	{
		if( $i == $on_page ) 
		{
			$page_string = $i;
		}
		
	}
	return $page_string;
}

#
#-----[ OPEN ]---------------------------------
#
includes/functions_post.php

#
#-----[ FIND ]---------------------------------
#
				$sql = "DELETE FROM " . TOPICS_TABLE . " 
					WHERE topic_id = $topic_id 
						OR topic_moved_id = $topic_id";
				if (!$db->sql_query($sql))
				{
					message_die(GENERAL_ERROR, 'Error in deleting post', '', __LINE__, __FILE__, $sql);
				}

#
#-----[ AFTER, ADD ]---------------------------------
#

			$sql = "DELETE FROM " . THANKS_TABLE . "
				WHERE topic_id = $topic_id";
			if (!$db->sql_query($sql))
			{
				message_die(GENERAL_ERROR, 'Error in deleting Thanks post Information', '', __LINE__, __FILE__, $sql);
			}

#
#-----[ OPEN ]------------------------------------------ 
#
language/lang_english/lang_main.php

#
#-----[ FIND ]---------------------------------
#
?>

#
#-----[ BEFORE, ADD ]------------------------------------------ 
#
// Begin FavPal Mod
$lang['thankful'] = 'Thankful People';
$lang['thanks_to'] = 'Thanks';
$lang['thanks_end'] = 'for his/her post';
$lang['thanks_alt'] = 'Thank Post';
$lang['thanked_before'] = 'You have already thanked this topic';
$lang['thanks_add'] = 'Your thanks has been given';
$lang['thanks_not_logged'] = 'You need to log in to thank someone\'s post';
$lang['thanked'] = 'user(s) is/are thankful for this post.';
$lang['hide'] = 'Hide';
$lang['t_starter'] = 'You cannot thank yourself';
$lang['thank_no_exist'] = 'Forum thank information doesn\'t exists';
// End FavPal Mod

#
#-----[ OPEN ]---------------------------------
#
templates/subSilver/subSilver.cfg

#
#-----[ FIND ]---------------------------------
#
$images['reply_locked'] = "$current_template_images/{LANG}/reply-locked.gif";

#
#-----[ AFTER, ADD ]---------------------------------
#
$images['thanks'] = "$current_template_images/{LANG}/thanks.gif";

#
#-----[ OPEN ]---------------------------------
#
templates/subSilver/viewtopic_body.tpl

#
#-----[ FIND ]---------------------------------
# This is a partial line, the complete line is much longer
#
		<td width="150" align="left" valign="top" class="{postrow.ROW_CLASS}">

#
#-----[ IN-LINE FIND ]---------------------------------
#
</td>

#
#-----[ AFTER, ADD ]---------------------------------
#
{postrow.FAVPAL_IMG}

#
#-----[ FIND ]---------------------------------
#
	<!-- END postrow -->

#
#-----[ BEFORE, ADD ]---------------------------------
#
<!-- BEGIN thanks -->
<tr>
	<td colspan="2" class="row2">
		<table class="forumline" cellspacing="1" cellpadding="3" border="0" width="100%">
			<tr>
				<th class="thLeft">{postrow.thanks.THANKFUL}</th>
			</tr>
			<tr>
				<td class="row2" valign="top" align="left">
					<span id="show_thank" style="display: block;" class="gensmall">
						{postrow.thanks.THANKS}&nbsp;
						<br />
					</span>
				</td>	
			</tr>
		</table>
	</td>
</tr>
<!-- END thanks -->

#
#-----[ OPEN ]---------------------------------
#
templates/subSilver/profile_add_body.tpl

#
#-----[ FIND ]---------------------------------
#
	<tr> 
	  <td class="catSides" colspan="2" height="28">&nbsp;</td>
	</tr>
	<tr> 
	  <th class="thSides" colspan="2" height="25" valign="middle">{L_PREFERENCES}</th>
	</tr>

#
#-----[ BEFORE, ADD ]---------------------------------
#

	<tr> 
	  <td class="catSides" colspan="2" height="28">&nbsp;</td>
	</tr>
	<tr> 
	  <th class="thSides" colspan="2" height="25" valign="middle">{L_FAVPAL_INFO}</th>
	</tr>
	<!-- BEGIN favpal_no_edit_profile -->
	<tr> 
	  <td class="row2" colspan="2"><span class="gensmall">{L_FAVPAL_INFO_NOTICE}</span></td>
	</tr>
	<tr> 
	  <td class="row1"><span class="gen">{L_FAVPAL_USER}:</span></td>
	  <td class="row2"> 
		<input type="hidden" name="favpal_user" value="{FAVPAL_USER}" /><span class="gen"><b>{FAVPAL_USER}</b></span>
	  </td>
	</tr>
	<tr>
	  <td class="row1"><span class="gen">{L_FAVPAL_PASS}:</span></td>
	  <td class="row2">
		<input type="password" class="post" style="width: 200px" name="favpal_password" size="25" maxlength="32" value="{FAVPAL_PASSWORD}" />
	  </td>
	  <input type="hidden" class="post" name="favpal_oper" value="{FAVPAL_OPER}">
	</tr>
	<!-- END favpal_no_edit_profile -->
	<!-- BEGIN favpal_edit_profile -->
	<tr> 
	  <td class="row2" colspan="2"><span class="gensmall">{L_FAVPAL_INFO_NOTICE}</span></td>
	</tr>
	<tr> 
	  <td class="row1"><span class="gen">{L_FAVPAL_USER}:</span></td>
	  <td class="row2">
		<input type="text" class="post" style="width:200px" name="favpal_user" size="25" maxlength="25" value="{FAVPAL_USER}" />
	  </td>
	</tr>
	<tr>
	  <td class="row1"><span class="gen">{L_FAVPAL_PASS}:</span></td>
	  <td class="row2">
		<input type="password" class="post" style="width: 200px" name="favpal_password" size="25" maxlength="32" value="{FAVPAL_PASSWORD}" />
	  </td>
	  <input type="hidden" class="post" name="favpal_oper" value="{FAVPAL_OPER}">
	</tr>
	<!-- END favpal_edit_profile -->

#
#-----[ SAVE/CLOSE ALL FILES ]------------------------------------------ 
#
# EoM
