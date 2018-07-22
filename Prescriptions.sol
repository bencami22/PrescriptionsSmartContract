pragma solidity ^ 0.4 .0;
import "https://github.com/Arachnid/solidity-stringutils/strings.sol";

contract Prescriptions {
    using strings
    for * ;

    struct Prescription {
        address medicalPractitioner;
        address patient;

        uint dateCreated;

        string[] medications;

        bool dispensed;
        address dispenser;
        uint dateDispensed;
    }

    enum MedicalPractitionerType {
        PRESCRIBER,
        DISPENSER
    }

    struct MedicalPractitioner {
        address medicalPractitioner;
        string licenseNumber;
        MedicalPractitionerType medicalPractitionerType;
    }

    Prescription[] internal prescriptions;

    MedicalPractitioner[] internal medicalPractitioners;

    function addMedicalPractitioner(string licenseNumber, MedicalPractitionerType medicalPractitionerType) public returns(uint) {
        medicalPractitioners.length++;
        medicalPractitioners[medicalPractitioners.length - 1].medicalPractitioner = msg.sender;
        medicalPractitioners[medicalPractitioners.length - 1].licenseNumber = licenseNumber;
        medicalPractitioners[medicalPractitioners.length - 1].medicalPractitionerType = medicalPractitionerType;

        return medicalPractitioners.length - 1;
    }

    event PrescriptionCreated(uint index, address medicalPractitioner, address patient, uint dateCreated, string medications);

    function addPrescription(address patient, string medicationsCSV) public returns(uint) {

        prescriptions.length++;
        prescriptions[prescriptions.length - 1].patient = patient;

        var delim = ",".toSlice();
        prescriptions[prescriptions.length - 1].medications = new string[](medicationsCSV.toSlice().count(delim) + 1);
        for (uint i = 0; i < prescriptions[prescriptions.length - 1].medications.length; i++) {
            prescriptions[prescriptions.length - 1].medications[i] = medicationsCSV.toSlice().split(delim).toString();
        }

        prescriptions[prescriptions.length - 1].medicalPractitioner = msg.sender;
        prescriptions[prescriptions.length - 1].dateCreated = now;

        //emit the event to any subscribers
        emit PrescriptionCreated(prescriptions.length - 1, prescriptions[prescriptions.length - 1].medicalPractitioner, prescriptions[prescriptions.length - 1].patient, prescriptions[prescriptions.length - 1].dateCreated, medicationsCSV);

        return prescriptions.length - 1;
    }

    function getPrescriptionCount() public constant returns(uint) {
        return prescriptions.length;
    }
    
    event PrescriptionDispensed(uint index, address dispenser, address patient, uint dateDispensed, string medicationsCSV);
    
    function dispensePrescription(uint index, address patient) public returns(string) {
        //prescriptions.length>index

        //prescriptions[index].dispensed
        var returnStr = "Prescription cannot be dispensed";
        if (patient == prescriptions[index].patient) {
            prescriptions[index].dispensed = true;
            prescriptions[index].dispenser = msg.sender;
            prescriptions[index].dateDispensed = now;

            //concatenation to build the csv, probably costly, to re visit.

            for (uint i = 0; i < prescriptions[index].medications.length; i++) {
                returnStr = prescriptions[index].medications[i].toSlice().concat(returnStr.toSlice());
            }
            emit PrescriptionDispensed(index, prescriptions[index].dispenser,patient, prescriptions[index].dateDispensed, returnStr);
        }
        return returnStr;

    }
}