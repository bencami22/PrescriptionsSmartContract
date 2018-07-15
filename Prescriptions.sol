pragma solidity ^0.4.0;
import "https://github.com/Arachnid/solidity-stringutils/strings.sol";

contract Prescriptions {
    using strings for *;
    
    struct Prescription {
        address medicalPractitioner;
        address patient;
        
        uint dateCreated;
    
        string[] medications;
    
        bool dispensed;
        address dispenser;
        uint dateDispensed;
    }
    
    Prescription[] internal prescriptions;
    
   function addPrescription(address patient, string medicationsCSV) public returns(uint) {

        prescriptions.length++;
        prescriptions[prescriptions.length-1].patient=patient;
        
        var delim = ",".toSlice();
        prescriptions[prescriptions.length-1].medications = new string[](medicationsCSV.toSlice().count(delim) + 1);
        for(uint i = 0; i < prescriptions[prescriptions.length-1].medications.length; i++) {
            prescriptions[prescriptions.length-1].medications[i] = medicationsCSV.toSlice().split(delim).toString();
        }

        prescriptions[prescriptions.length-1].medicalPractitioner = msg.sender;
        prescriptions[prescriptions.length-1].dateCreated = now;
        
        return prescriptions.length-1;
    }

    function getPrescriptionCount() public constant returns(uint) {
        return prescriptions.length;
    }

    function dispensePrescription(uint index, address patient) public returns(string) {
        //prescriptions.length>index
        
        //prescriptions[index].dispensed
        
        if(patient==prescriptions[index].patient)
        {
            prescriptions[index].dispensed=true;
            prescriptions[index].dispenser=msg.sender;
            prescriptions[index].dateDispensed=now;
            
            //concatenation to build the csv, probably costly, to re visit.
            var returnStr="";
            for(uint i=0;i<prescriptions[index].medications.length;i++)
            {
                returnStr=prescriptions[index].medications[i].toSlice().concat(returnStr.toSlice());
            }
            return returnStr;
        }
    }
}