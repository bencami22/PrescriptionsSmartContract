pragma solidity ^0.4.0;
contract Prescriptions {
    struct Prescription {
        address medicalPractitioner;
        address patient;
    
        uint dateCreated;
    
        bool dispensed;
        address dispenser;
        uint dateDispensed;
    }
    
    Prescription[] internal prescriptions;
  
}