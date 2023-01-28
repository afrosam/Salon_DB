#! /bin/bash
PSQL='psql -X --username=freecodecamp --dbname=salon --tuples-only -c'
echo -e "\n~~~~~  Welcome To The Salon  ~~~~~\n"

MAIN_MENU() {
  if [[ $1 ]]
  then
    echo -e $1
  fi
  echo -e "How may we help you today?\n"
  LIST_OF_SERVICES=$($PSQL "select * from services")
  echo "$LIST_OF_SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done

  read SERVICE_ID_SELECTED
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    MAIN_MENU "Selection given must be a number."
  else # user input is a number
    SERVICE_EXISTS=$($PSQL "SELECT service_id FROM services WHERE service_id=$SERVICE_ID_SELECTED")
    if [[ -z $SERVICE_EXISTS ]]
    then
      # service id does not exist, return to main menu
      MAIN_MENU "The service you have entered does not exist within our records."
    else
      # service exists
      echo -e "\nWhat is your phone number?"
      read CUSTOMER_PHONE
      if [[ ! $CUSTOMER_PHONE =~ ^[0-9\-]+$ ]]
      then # contains letters, not a valid phone number
        MAIN_MENU "\nThe number you have input does not appear to be valid:\n $CUSTOMER_PHONE\n"
      else
        CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
        # phone number exists?
        if [[ -z $CUSTOMER_NAME ]]
        then
          # customer does not exist
          echo -e "\nNo customer with that phone number appears in our records."
          # add them to database
          echo -e "\nWhat is your name?"
          read CUSTOMER_NAME
          echo $($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
        fi
        NAME=$(echo $CUSTOMER_NAME | sed 's/^ //g')
        echo -e "\nWelcome back $NAME"
        echo -e "\nOur open hours are 8am - 5pm\nWhat time were you looking to schedule an appointment?"
        read SERVICE_TIME
        ID=$($PSQL "SELECT customer_id FROM customers WHERE name = '$NAME'")
        C_ID=$(echo $ID | sed 's/^[\s]+//g')
        echo -e "name: '$NAME'\ncustomer_id: '$C_ID'\ntime: $SERVICE_TIME"
        echo $($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($C_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
        SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = '$SERVICE_ID_SELECTED'")
        S_NAME=$(echo $SERVICE_NAME | sed 's/^\s//g')
        echo -e "I have put you down for a $S_NAME at $SERVICE_TIME, $NAME."
        EXIT
      fi
    fi
  fi
}

EXIT() {
  echo "Thank you for your patronage!"
}

MAIN_MENU
