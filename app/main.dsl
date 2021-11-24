import "commonReactions/all.dsl";

context 
{
    // declare input variables here
    input phone: string;

    // declare storage variables here 
    name: string = ""; 
    policy_number: string = ""; 
    policy_read: string = "";
    email: string = "";
    
}

// declare external functions here 
external function check_policy(policy_number: string): string;
external function convert_policy(policy_number: string): string;
external function split_name(name: string): string;

// lines 28-42 start node 
start node root 
{
    do //actions executed in this node 
    {
        #connectSafe($phone); // connecting to the phone number which is specified in index.js that it can also be in-terminal text chat
        #waitForSpeech(1000); // give the person a second to start speaking 
        #sayText("Hello, welcome to ACME insurance. My name is Dasha, how can I help you today?"); 
        wait *; // wait for a response
    }
    transitions // specifies to which nodes the conversation goes from here 
    {

    }
}

node accident
{
    do
    {
        set $name =  #messageGetData("name")[0]?.value??""; //assign variable $name with the value extracted from the user's previous statement 
        #log($name);
        set $name = external split_name($name);
        #sayText("Wonderful, thank you for that " + $name + ". To initiate the claim process, let’s start with some basic information. Could you tell me the date of loss?");
        wait*;
    }
    transitions
    {
        injured: goto injured on #messageHasData("number_word") or #messageHasData("month");
    }
}

node injured
{
    do
    {
        #sayText("Sorry about your horrible experience. Was anyone injured or involved in the accident?");
        wait*;
    }
    transitions
    {
        collision: goto collision on #messageHasIntent("no_injured") or #messageHasIntent("no");
    }
}

node collision
{
    do
    {
        #sayText("Perfect. Now, could you tell me where the collision happened?");
        wait*;
    }
    transitions
    {
        witnesses: goto witnesses on #messageHasData("address");
    }
}

node witnesses
{
    do
    {
        #sayText("Were there any witnesses of the accident?");
        wait*;
    }
    transitions
    {
        email_witness: goto email_witness on #messageHasIntent("yes_witness") or #messageHasIntent("yes");
    }
}

node email_witness
{
    do
    {
        #sayText("Could you tell me your husband's email address please?");
        wait*;
    }
    transitions
    {
        authorities: goto authorities on #messageHasData("email");
    }
}

node authorities
{
    do
    {
        #sayText("Got you." +$email + ". Did you inform any authorities right away?");
        wait*;
    }
    transitions
    {
        car_details: goto car_details on #messageHasIntent("authorities") or #messageHasIntent("no");
    }
}

node car_details
{
    do
    {
        #sayText("Alright. Thank you for answering my questions this far. Now I need the details of your car. Let’s start with the car make and model.");
        wait*;
    }
    transitions
    {
        licence_plate: goto licence_plate on #messageHasData("car_make") or #messageHasData("car_model");
    }
}

node licence_plate
{
    do
    {
        #sayText("Thank you. Could you tell me the licence plate number?");
        wait*;
    }
    transitions
    {
        damage_car: goto damage_car on #messageHasData("licence_plate");
    }
}

node damage_car
{
    do
    {
        #sayText("Uh-huh, noted. Could you describe the damage to the car, please?");
        wait*;
    }
    transitions
    {
        policy_holder_the_driver: goto policy_holder_the_driver on #messageHasData("damage_car");
    }
}



node policy_holder_the_driver
{
    do
    {
        #sayText("Were you as the policy holder driving the car");
        wait*;
    }
    transitions
    {
        final: goto final on #messageHasIntent("yes");
    }
}

digression fnol
{
    conditions {on #messageHasIntent("fnol") or #messageHasIntent("accident");}
    do 
    {
        #sayText("Can you please share your policy number?"); 
        wait*;
    }
    transitions
    {
        policy_2: goto policy_2 on #messageHasData("policy");
    }
}

node policy_2
{
    do 
    {
        set $policy_number = #messageGetData("policy")[0]?.value??"";
        set $policy_read = external convert_policy($policy_number);
        #log($policy_read);
        #sayText("Okay, let me check. Policy number "); 
        #say("confirm_policy" , {policy_read: $policy_read} );
        #sayText("It looks like your coverage limit is 5 thousand dollars and experation date is November second 2024. Now, could you confirm your first and last name to me, please?");
        wait*;
    }
    transitions
    {
        accident: goto accident on #messageHasData("name"); 
    }
}

node final 
{
    do
    {
        #sayText("Good to know. At this point I will send you an email with a DocuSign link. You check all the information on the FNOL form and then we will process your claim. Thank you and goodbye!");
        exit;
    }
}

digression bye
{
    conditions {on #messageHasIntent("bye");}
    do
    {
        #sayText("Thanks for your time! Bye!");
        exit;
    }
}
