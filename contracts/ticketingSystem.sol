pragma solidity ^0.6.0;

contract ticketingSystem {

    artist[] public artistsRegister;
    venue[] public venuesRegister;
    concert[] public concertsRegister;
    ticket[] public ticketsRegister;
    //Should use mapping instead of array to store the data
    uint public artistCount = 0;
    uint public venueCount = 0;
    uint public concertCount = 0;
    uint public ticketCount = 0;

    struct artist{
        bytes32 name;
        uint artistCategory;
        address payable owner;
        uint totalTicketSold;
    }

    struct venue{
        bytes32 name;
        uint capacity;
        uint standardComission;
        address payable owner;
    }

    struct concert{
        uint artistId;
        uint venueId;
        uint concertDate;
        uint ticketPrice;
        bool validatedByArtist;
        bool validatedByVenue;
        uint totalSoldTicket;
        uint totalMoneyCollected;
    }

    struct ticket{
        uint concertId;
        address payable owner;
        bool isAvailable;
        uint amountPaid;
        bool isAvailableForSale;
    }
    //01_creatingArtistProfile
    function createArtist(bytes32 _artistName, uint _artistCategory) public {
        if (artistCount == 0){
            artistsRegister.push();
            artistsRegister.push(artist(_artistName, _artistCategory, msg.sender, 0));
            }
        else{artistsRegister.push(artist(_artistName, _artistCategory, msg.sender, 0));}
        artistCount++;
    }

    function modifyArtist(uint _artistId, bytes32 _name, uint _artistCategory, address payable _newOwner) public {
        require(msg.sender == artistsRegister[_artistId].owner,"");
        artistsRegister[_artistId] = artist(_name, _artistCategory, _newOwner, 0);
    }

    //02_creatingVenue
    function createVenue(bytes32 _name, uint _capacity, uint _standardComission) public {
        if (venueCount == 0){
            venuesRegister.push();
            venuesRegister.push(venue(_name,_capacity,_standardComission, msg.sender));
            }
        else{venuesRegister.push(venue(_name,_capacity,_standardComission, msg.sender));}
        venueCount++;
    }

    function modifyVenue(uint _venueId, bytes32 _name, uint _capacity, uint _standardComission, address payable _newOwner) public {
        require(msg.sender == venuesRegister[_venueId].owner,"");
        venuesRegister[_venueId] = venue(_name,_capacity,_standardComission, _newOwner);
    }

    //03_concertManagement
    function createConcert(uint _artistId, uint _venueId, uint _concertDate, uint _ticketPrice) public{
        address ArtistOwner = artistsRegister[_artistId].owner;
        bool validateArtist = false;
        if(msg.sender == ArtistOwner){
            validateArtist = true;
        }
        if (concertCount == 0){
            concertsRegister.push();
            concertsRegister.push(concert(_artistId, _venueId, _concertDate, _ticketPrice, validateArtist, false, 0, 0));
            }
        else{concertsRegister.push(concert(_artistId, _venueId, _concertDate, _ticketPrice, validateArtist, false, 0, 0));}
        concertCount++;
    }

    function validateConcert (uint _concertId) public{
        uint _artistId = concertsRegister[_concertId].artistId;
        uint _venuesId = concertsRegister[_concertId].venueId;

        address ArtistOwner = artistsRegister[_artistId].owner;
        address VenueOwner = venuesRegister[_venuesId].owner;
        if(msg.sender == ArtistOwner){
            concertsRegister[_concertId].validatedByArtist = true;
        }
        else if(msg.sender == VenueOwner){
            concertsRegister[_concertId].validatedByVenue = true;
        }
    }

    function emitTicket(uint _concertId, address payable _ticketOwner) public {
        uint _artistId = concertsRegister[_concertId].artistId;
        address ArtistOwner = artistsRegister[_artistId].owner;
        require(msg.sender == ArtistOwner,"");
        if (ticketCount == 0){
            ticketsRegister.push();
            ticketsRegister.push(ticket(_concertId, _ticketOwner, true, 0, true));
            }
        else{ticketsRegister.push(ticket(_concertId, _ticketOwner, true, 0, true));}
        concertsRegister[_concertId].totalSoldTicket++;
        ticketCount++;
    }

    function useTicket(uint _ticketId) public{
        require(msg.sender == ticketsRegister[_ticketId].owner,"Sender is not the owner of this ticket");
        require(now > (concertsRegister[ticketsRegister[_ticketId].concertId].concertDate - 60*60*24), "The concert is not today");
        require(concertsRegister[ticketsRegister[_ticketId].concertId].validatedByVenue == true,"Not validated by venue yet");
        ticketsRegister[_ticketId].isAvailable = false;
        ticketsRegister[_ticketId].owner = 0x0000000000000000000000000000000000000000;
    }

    //04_TicketBuyingAndTransferring
    function buyTicket(uint _concertId) public payable{
        require(concertsRegister[_concertId].ticketPrice <= msg.value,"Not enough money");
        ticket memory _ticket = ticket(_concertId, msg.sender, true, concertsRegister[_concertId].ticketPrice, false);
        if(ticketCount == 0){ticketsRegister.push();}
        ticketsRegister.push(_ticket);
        ticketCount++;
        concertsRegister[_concertId].totalSoldTicket++;
        concertsRegister[_concertId].totalMoneyCollected += _ticket.amountPaid;
        artistsRegister[concertsRegister[_concertId].artistId].totalTicketSold ++;
    }

    function transferTicket(uint _ticketId, address payable _newOwner) public{
        require(ticketsRegister[_ticketId].owner == msg.sender, "Should be the owner of the ticket");
        ticketsRegister[_ticketId].owner = _newOwner;
    }

    //05_ConcertCashOut
    function cashOutConcert(uint _concertId, address payable _cashOutAddress) public{
        require(msg.sender == artistsRegister[concertsRegister[_concertId].artistId].owner,"Should be the artist");
        require(now >= concertsRegister[_concertId].concertDate, "Should be after the concert");

        uint totalCash = concertsRegister[_concertId].totalMoneyCollected;
        uint venueCash = venuesRegister[concertsRegister[_concertId].venueId].standardComission;
        uint artistCash = totalCash - venueCash;

        venuesRegister[concertsRegister[_concertId].venueId].owner.transfer(venueCash);
        _cashOutAddress.transfer(artistCash);
    }

    //06_TicketSelling
    function offerTicketForSale(uint _ticketId, uint _salePrice) public{
        require(msg.sender == ticketsRegister[_ticketId].owner, "Should be the owner of the ticket");
        require(ticketsRegister[_ticketId].amountPaid > _salePrice,"Should be cheaper than the amount initially paid");

        ticketsRegister[_ticketId].amountPaid = _salePrice;
        ticketsRegister[_ticketId].isAvailable = true;
        ticketsRegister[_ticketId].isAvailableForSale = true;

    }

    function buySecondHandTicket(uint _ticketId) public payable{
        //need enough money
        require(ticketsRegister[_ticketId].amountPaid <= msg.value, "Not enough funds");
        require(ticketsRegister[_ticketId].isAvailable == true, "The ticket should be available");

        ticketsRegister[_ticketId].owner = msg.sender;
        //not available for sale anymore
        ticketsRegister[_ticketId].isAvailable = false;

    }


}