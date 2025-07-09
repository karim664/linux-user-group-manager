#!/bin/bash

# ==== Check for Root Privileges ====
if [ "$EUID" -ne 0 ]; then
  whiptail --title "Permission Denied" --msgbox "This script must be run as root!" 10 60
  exit 1
fi

show_menu () {
choice=$(whiptail --title "Main Menu" --menu "Choose an option" 25 80 15 \
" "  "|────────── User Management ──────────────────|" \
"1"  "| Add User        - Create New User           |" \
"2"  "| Modify User     - Edit an Existing User     |" \
"3"  "| Delete User     - Delete an Existing User   |" \
"4"  "| List Users      - List All Users            |" \
" "  "|────────── Group Management ─────────────────|" \
"5"  "| Add Group       - Create New Grضoup          |" \
"6"  "| Modify Group    - Modify an Existing Group  |" \
"7"  "| Delete Group    - Delete an Existing Group  |" \
"8"  "| List Groups     - List All Groups           |" \
" "  "|────────── Administration ───────────────────|" \
"9"  "| Disable User    - Lock User Account         |" \
"10" "| Enable User     - Unlock User Account       |" \
"11" "| Change Password - Change User Password      |" \
"12" "| About           - Info About This Program   |" \
"13" "| Exit            - Exit This Program         |" \
3>&1 1>&2 2>&3 )
status=$?
}

invalid_check() {
    whiptail  --msgbox "This is not a valid option" 10 60
}

#Adding user function

adduser() {
    #check if the user name is empty or exist

    while true 
    do
        user_name=$(whiptail  --inputbox "Enter username:" 10 60 3>&1 1>&2 2>&3) status=$?
        if [ $status -ne 0 ] ; then
            return 1 

        elif [ -z "$user_name" ] ; then
            whiptail  --msgbox "User Name CAN NOT be empty" 10 60 
            continue

        elif grep -q "^$user_name:" /etc/passwd ; then 
            whiptail --title "Error" --msgbox "User '$user_name' already exists!" 10 60
            continue 
        
        else
            break
        fi
    done

    #Obtaining user password and confirm it

    while true 
    do
        user_password=$(whiptail  --passwordbox \
        "Enter a Password" 10 60 3>&1 1>&2 2>&3) status=$?

        if [ $status -ne 0 ] ; then
            return 1 

        elif [ -z "$user_password" ] ; then
            whiptail  --msgbox "Please Enter a Password" 10 60
            continue

        elif [ ${#user_password} -lt 6 ] ; then
            whiptail  --msgbox "Your password is Too weak(press enter to continue)" 10 60
        fi

        user_password_confirm=$(whiptail  --passwordbox \
        "Enter your Password again" 10 60 3>&1 1>&2 2>&3) status=$?

        if [ $status -ne 0 ] ; then
            break
        fi

        if [ "$user_password" = "$user_password_confirm"  ] ; then
            break
        
        else 
            whiptail --msgbox "Passwords Doesn't match" 10 60
            continue
        fi
    done

#optionals
#1-uid checks

    while true ;
    do
    user_uid=$(whiptail --inputbox "Enter a UID (1000 ~ 60000) (optional)" 10 60 3>&1 1>&2 2>&3) status=$?

    if [ $status -ne 0 ]; then
        return 1   
    fi

    if [[ -n "$user_uid" && ! "$user_uid" =~ ^[0-9]+$ ]]; then
        whiptail --msgbox "UID Must Be a Number" 10 60
        continue
    
    
    fi

    if cut -d : -f3 /etc/passwd |grep -q "$user_uid"  ; then
    whiptail --msgbox "UID already exist" 10 60
    continue

    else
    break

    fi

    done

#2-user group checks

    while true; do
    user_group=$(whiptail --inputbox "Enter Group Name (optional)" 10 60 3>&1 1>&2 2>&3)
    status=$?

    if [ $status -ne 0 ]; then
        return 1  
    fi

    if [ -n "$user_group" ]; then
        if getent group "$user_group" >/dev/null; then
            whiptail --msgbox "Group '$user_group' already exists!" 10 60
            continue
        fi
    else
        if getent group "$user_name" >/dev/null; then
            whiptail --msgbox "Warning group '$user_name' alread exist choose a different one" 10 60
            continue
        fi
    fi
        break
done


    user_comment=$(whiptail --inputbox "Enter user's Full Name (optional)" 10 60 3>&1 1>&2 2>&3) status=$?
    
    if [ $status -ne 0 ]; then
        return 1  
    fi

    user_shell=$(whiptail --inputbox "Enter Your Desired Shell (optional)" 10 60 "/bin/bash"  3>&1 1>&2 2>&3) status=$?
   
    if [ $status -ne 0 ]; then
        return 1   
    fi

    encrypted_password=$(openssl passwd -6 "$user_password")
    user_add_cmd="useradd ${user_name} -p '${encrypted_password}'"


    if [ -n "$user_uid" ] ; then
        user_add_cmd+=" -u ${user_uid}"
    fi

    if [ -n "$user_comment" ] ; then
        user_add_cmd+=" -c \"${user_comment}\""
    fi

    if [ -n "$user_shell" ] ; then
        user_add_cmd+=" -s ${user_shell}"
    fi

    if [ -n "$user_group" ] ; then
        user_add_cmd+=" -g ${user_group}"
    fi

    whiptail --title "Summary" --yesno "\n 
    User Name           = ${user_name} 
    UID                 = ${user_uid} 
    User Group          = ${user_group}
    Full Name (comment) = ${user_comment}
    Shell               = ${user_shell} \n
    >>>>>>>>>>>Confirm ?<<<<<<<<<<< " 15 60
    status=$?

     if [ $status -ne 0 ] ; then
            return 1

    else
    groupadd "$user_group"
    eval "$user_add_cmd"
    fi 

    if [ $? -ne 1 ] ; then 
        whiptail --msgbox "User: ${user_name} has been added successfully" 10 60
    fi

}

#edit user name
editusername(){
    while true; do
        old_user_name=$(whiptail  --inputbox "Enter The Username:" 10 60 3>&1 1>&2 2>&3)
        status=$?

        if [ $status -ne 0 ]; then
            return 1
        elif [ -z "$old_user_name" ]; then
            whiptail  --msgbox "User Name CAN NOT be empty" 10 60
            continue
        elif ! grep -q "^$old_user_name:" /etc/passwd ; then
            whiptail --msgbox "User '$old_user_name' does not exist!" 10 60
            continue
        fi

       
        while true; do
            new_user_name=$(whiptail  --inputbox "Enter The New Username:" 10 60 3>&1 1>&2 2>&3)
            status=$?
            if [ $status -ne 0 ]; then
                return 1
            elif [ -z "$new_user_name" ]; then
                whiptail  --msgbox "User Name CAN NOT be empty" 10 60
                continue
            elif grep -q "^$new_user_name:" /etc/passwd ; then
                whiptail --title "Error" --msgbox "User '$new_user_name' already exists!" 10 60
                continue
            else
                usermod -l "$new_user_name" "$old_user_name"
                whiptail --msgbox "User renamed successfully!" 10 60
                break  
            fi
        done
        break  
    done
}

#edit user password
edituserpassword() {
    while true;
     do  
        user_name=$(whiptail --inputbox "Enter username:" 10 60 3>&1 1>&2 2>&3)
        status=$?
        
        if [ $status -ne 0 ]; then
            return 1 
        elif [ -z "$user_name" ]; then
            whiptail --msgbox "User Name CAN NOT be empty" 10 60 
            continue
        elif ! grep -q "^$user_name:" /etc/passwd; then
            whiptail --msgbox "User does not exist!" 10 60
            continue
        fi

        # Password input
        new_user_password=$(whiptail --passwordbox "Enter your new password" 10 60 3>&1 1>&2 2>&3)
        status=$?

        if [ $status -ne 0 ]; then
            return 1
        elif [ -z "$new_user_password" ]; then
            whiptail --msgbox "Password can't be empty" 10 60
            continue
        fi

        new_user_password_check=$(whiptail --passwordbox "Please Re-enter your new password" 10 60 3>&1 1>&2 2>&3)
        status=$?

        if [ $status -ne 0 ]; then
            return 1
        elif [ "$new_user_password" != "$new_user_password_check" ]; then
            whiptail --msgbox "Passwords don't match" 10 60
            continue
        fi

        new_encrypted_password=$(openssl passwd -6 "$new_user_password")
        usermod -p "$new_encrypted_password" "$user_name"
        whiptail --msgbox "Password updated successfully!" 10 60
        break
    done
}

editprimarygroup() {
    while true; do
        user_name=$(whiptail --inputbox "Enter Username:" 10 60 3>&1 1>&2 2>&3) || return 1

        if ! id "$user_name" &>/dev/null; then
            whiptail --msgbox "User does not exist!" 10 60
            continue
        fi

        new_group=$(whiptail --inputbox "Enter New Primary Group:" 10 60 3>&1 1>&2 2>&3) || return 1

        if ! getent group "$new_group" &>/dev/null; then
            whiptail --yesno "Group does not exist. Do you want to create it?" 10 60
            if [ $? -eq 0 ]; then
                groupadd "$new_group" || {
                    whiptail --msgbox "Failed to create group!" 10 60
                    continue
                }
            else
                continue
            fi
        fi

        usermod -g "$new_group" "$user_name" && whiptail --msgbox "Primary group updated!" 10 60
        break
    done
}


editsecondarygroup() {
    while true; do
        user_name=$(whiptail --inputbox "Enter Username:" 10 60 3>&1 1>&2 2>&3) || return 1

        if ! id "$user_name" &>/dev/null; then
            whiptail --msgbox "User does not exist!" 10 60
            continue
        fi

        groups=$(whiptail --inputbox "Enter Secondary Groups (comma-separated):" 10 60 3>&1 1>&2 2>&3) || return 1
        usermod -G "$groups" "$user_name" && whiptail --msgbox "Secondary groups updated!" 10 60
        break
    done
}

editusershell() {
    while true; do
        user_name=$(whiptail --inputbox "Enter Username:" 10 60 3>&1 1>&2 2>&3) || return 1

        if ! id "$user_name" &>/dev/null; then
            whiptail --msgbox "User does not exist!" 10 60
            continue
        fi

        shell=$(whiptail --inputbox "Enter New Shell:" 10 60 3>&1 1>&2 2>&3) || return 1
        usermod -s "$shell" "$user_name" && whiptail --msgbox "Shell updated!" 10 60
        break
    done
}

edituseruid() {
    while true; do
        user_name=$(whiptail --inputbox "Enter Username:" 10 60 3>&1 1>&2 2>&3) || return 1

        if ! id "$user_name" &>/dev/null; then
            whiptail --msgbox "User does not exist!" 10 60
            continue
        fi

        uid=$(whiptail --inputbox "Enter New UID:" 10 60 3>&1 1>&2 2>&3) || return 1
        usermod -u "$uid" "$user_name" && whiptail --msgbox "UID updated!" 10 60
        break
    done
}

edithomedirectory() {
    while true; do
        user_name=$(whiptail --inputbox "Enter Username:" 10 60 3>&1 1>&2 2>&3) || return 1

        if ! id "$user_name" &>/dev/null; then
            whiptail --msgbox "User does not exist!" 10 60
            continue
        fi

        home_dir=$(whiptail --inputbox "Enter New Home Directory:" 10 60 3>&1 1>&2 2>&3) || return 1
        usermod -d "$home_dir" "$user_name" && whiptail --msgbox "Home directory updated!" 10 60
        break
    done
}

modifyuser() {
    while true; do
        choice1=$(whiptail --menu "Modify User Menu" 15 60 8 \
            "1" "User Name" \
            "2" "Password" \
            "3" "Primary Group" \
            "4" "Secondary Group" \
            "5" "Default Shell" \
            "6" "UID" \
            "7" "Home Directory" \
            "8" "Back to Main Menu" \
            3>&1 1>&2 2>&3)
        status=$?

        if [ $status -ne 0 ] || [ "$choice1" = "8" ]; then
            break
        fi

        case $choice1 in
            "1") editusername ;;
            "2") edituserpassword ;;
            "3") editprimarygroup ;;
            "4") editsecondarygroup ;;
            "5") editusershell ;;
            "6") edituseruid ;;
            "7") edithomedirectory ;;
        esac
    done
}
# 3- Delete User
deleteuser() {
    while true; do
        user_name=$(whiptail --inputbox "Enter Username to Delete:" 10 60 3>&1 1>&2 2>&3) || return 1

        if ! id "$user_name" &>/dev/null; then
            whiptail --msgbox "User does not exist!" 10 60
            continue
        fi

        whiptail --yesno "Are you sure you want to delete user '$user_name'?" 10 60
        status=$?
        if [ $status -eq 0 ]; then
            userdel -r "$user_name" && whiptail --msgbox "User '$user_name' deleted successfully!" 10 60
        fi
        break
    done
}

# 4- List Users
listusers() {
    tempfile=$(mktemp)
    cut -d: -f1 /etc/passwd | tail > "$tempfile"
    whiptail --title "List of Users" --textbox "$tempfile" 20 60
    rm -f "$tempfile"
}

# 5- Add Group
addgroup() {
    while true; do
        group_name=$(whiptail --inputbox "Enter Group Name:" 10 60 3>&1 1>&2 2>&3) || return 1

        if getent group "$group_name" &>/dev/null; then
            whiptail --msgbox "Group already exists!" 10 60
            continue
        fi

        groupadd "$group_name" && whiptail --msgbox "Group '$group_name' created successfully!" 10 60
        break
    done
}

# 6- Modify Group
modifygroup() {
    while true; do
        old_group=$(whiptail --inputbox "Enter Existing Group Name:" 10 60 3>&1 1>&2 2>&3) || return 1

        if ! getent group "$old_group" &>/dev/null; then
            whiptail --msgbox "Group does not exist!" 10 60
            continue
        fi

        new_group=$(whiptail --inputbox "Enter New Group Name:" 10 60 3>&1 1>&2 2>&3) || return 1

        if getent group "$new_group" &>/dev/null; then
            whiptail --msgbox "New group name already exists!" 10 60
            continue
        fi

        groupmod -n "$new_group" "$old_group" && whiptail --msgbox "Group renamed successfully!" 10 60
        break
    done
}

# 7- Delete Group
deletegroup() {
    while true; do
        group_name=$(whiptail --inputbox "Enter Group Name to Delete:" 10 60 3>&1 1>&2 2>&3) || return 1

        if ! getent group "$group_name" &>/dev/null; then
            whiptail --msgbox "Group does not exist!" 10 60
            continue
        fi

        whiptail --yesno "Are you sure you want to delete group '$group_name'?" 10 60
        status=$?
        if [ $status -eq 0 ]; then
            groupdel "$group_name" && whiptail --msgbox "Group '$group_name' deleted successfully!" 10 60
        fi
        break
    done
}

# 8- List Groups
listgroups() {
    groups=$(cut -d: -f1 /etc/group)
    whiptail --title "List of Groups" --msgbox "$groups" 20 60
}

# 9- Disable User (lock)
disableuser() {
    while true; do
        user_name=$(whiptail --inputbox "Enter Username to Lock:" 10 60 3>&1 1>&2 2>&3) || return 1

        if ! id "$user_name" &>/dev/null; then
            whiptail --msgbox "User does not exist!" 10 60
            continue
        fi

        usermod -L "$user_name" && whiptail --msgbox "User '$user_name' locked!" 10 60
        break
    done
}

# 10- Enable User (unlock)
enableuser() {
    while true; do
        user_name=$(whiptail --inputbox "Enter Username to Unlock:" 10 60 3>&1 1>&2 2>&3) || return 1

        if ! id "$user_name" &>/dev/null; then
            whiptail --msgbox "User does not exist!" 10 60
            continue
        fi

        usermod -U "$user_name" && whiptail --msgbox "User '$user_name' unlocked!" 10 60
        break
    done
}

# 11- Change Password (force)
changepassword() {
    while true; do
        user_name=$(whiptail --inputbox "Enter Username to Force Password Change:" 10 60 3>&1 1>&2 2>&3) || return 1

        if ! id "$user_name" &>/dev/null; then
            whiptail --msgbox "User does not exist!" 10 60
            continue
        fi

        chage -d 0 "$user_name" && whiptail --msgbox "User '$user_name' must change password at next login!" 10 60
        break
    done
}

# 12- About
about() {
    whiptail --title "About" --msgbox "Linux User & Group Management Tool\n\nMade by Karim - 2025" 15 60
}


# ==== Main Loop ====
while true; do
    show_menu
    if [ "$choice" = 13 ] || [ "$status" -ne 0 ]; then
        break
    fi

    case $choice in
        " ") invalid_check ;;
        1) adduser ;;
        2) modifyuser ;;
        3) deleteuser ;;
        4) listusers ;;
        5) addgroup ;;
        6) modifygroup ;;
        7) deletegroup ;;
        8) listgroups ;;
        9) disableuser ;;
        10) enableuser ;;
        11) changepassword ;;
        12) about ;;
    esac
done
