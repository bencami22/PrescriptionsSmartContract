pragma solidity ^ 0.4 .0;
import "https://github.com/Arachnid/solidity-stringutils/strings.sol";

contract Prescriptions {
    using strings
    for * ;

    address owner;

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
        BOTH,
        PRESCRIBER,
        DISPENSER
    }

    struct MedicalPractitioner {
        address medicalPractitioner;
        string licenseNumber;
        MedicalPractitionerType medicalPractitionerType;
        bool approved;
    }

    mapping(string => uint) prescriptionReferences;
    Prescription[] internal prescriptions;

    mapping(address => uint) medicalPractitionerMapping;
    MedicalPractitioner[] internal medicalPractitioners;

    constructor() public {
        owner = msg.sender;
        //take first entry of array
        prescriptions.length++;
        medicalPractitioners.length++;
    }

    function addMedicalPractitioner(string licenseNumber, MedicalPractitionerType medicalPractitionerType) public returns(uint) {
        medicalPractitioners.length++;
        medicalPractitioners[medicalPractitioners.length - 1].medicalPractitioner = msg.sender;
        medicalPractitioners[medicalPractitioners.length - 1].licenseNumber = licenseNumber;
        medicalPractitioners[medicalPractitioners.length - 1].medicalPractitionerType = medicalPractitionerType;

        medicalPractitionerMapping[msg.sender] = medicalPractitioners.length - 1;

        return medicalPractitioners.length - 1;
    }

    function approveMedicalPractitioner(address medicalPractitioner) public {
        if (owner != msg.sender) require(owner == msg.sender, 'RESTRICTED ACCESS- only owner allowed');
        uint medicalPractitionerIndex = medicalPractitionerMapping[medicalPractitioner];
        medicalPractitioners[medicalPractitionerIndex].approved = true;
    }

    event PrescriptionCreated(string reference, address medicalPractitioner, address patient, uint dateCreated, string medications);

    function addPrescription(string reference, address patient, string medicationsCSV) public returns(uint) {

        uint index = prescriptionReferences[reference.toSlice().concat(toString(patient).toSlice())];
        if (index != 0) revert('Not a valid prescription'); //0 means doesn't exist (index 0 is also taken by default unusuable value in cconstructor)
        uint medicalPractitionerIndex = medicalPractitionerMapping[msg.sender];
        if (medicalPractitionerIndex == 0) revert('Not a valid medical practitioner'); //means the sender address is not a medical practitioner. (index 0 is also taken by default unusuable value in cconstructor)
        if (medicalPractitioners[medicalPractitionerIndex].approved != true) require(medicalPractitioners[medicalPractitionerIndex].approved == true, 'Medical practitioner not yet approved'); //means the medical practitioner was not yet approved.
        if (medicalPractitioners[medicalPractitionerIndex].medicalPractitionerType != MedicalPractitionerType.BOTH &&
            medicalPractitioners[medicalPractitionerIndex].medicalPractitionerType != MedicalPractitionerType.PRESCRIBER) //medical practioner must by of MedicalPractitionerType BOTH or PRESCRIBER
            require(medicalPractitioners[medicalPractitionerIndex].medicalPractitionerType == MedicalPractitionerType.BOTH ||
                medicalPractitioners[medicalPractitionerIndex].medicalPractitionerType == MedicalPractitionerType.PRESCRIBER, 'Medical practioner must by of MedicalPractitionerType BOTH or PRESCRIBER');

        prescriptions.length++;
        prescriptions[prescriptions.length - 1].patient = patient;

        var delim = ",".toSlice();
        prescriptions[prescriptions.length - 1].medications = new string[](medicationsCSV.toSlice().count(delim) + 1);
        for (uint i = 0; i < prescriptions[prescriptions.length - 1].medications.length; i++) {
            prescriptions[prescriptions.length - 1].medications[i] = medicationsCSV.toSlice().split(delim).toString();
        }

        prescriptions[prescriptions.length - 1].medicalPractitioner = msg.sender;
        prescriptions[prescriptions.length - 1].dateCreated = now;

        prescriptionReferences[reference.toSlice().concat(toString(patient).toSlice())] = prescriptions.length - 1;

        //emit the event to any subscribers
        emit PrescriptionCreated(reference, prescriptions[prescriptions.length - 1].medicalPractitioner, prescriptions[prescriptions.length - 1].patient, prescriptions[prescriptions.length - 1].dateCreated, medicationsCSV);

        return prescriptions.length - 1;
    }

    function getPrescriptionCount() public constant returns(uint) {
        return prescriptions.length;
    }

    function getPrescription(string reference, address patient) public constant returns(address medicalPractitioner,
        uint dateCreated, string medications, bool dispensed, address dispenser, uint dateDispensed) {
        uint index = prescriptionReferences[reference.toSlice().concat(toString(patient).toSlice())];
        if (index == 0) revert('Prescription does not exist'); //0 means doesn't exist (index 0 is also taken by default unusuable value in cconstructor)

        Prescription memory p = prescriptions[index];
        string memory medicationsCSV = "";
        //concatenation to build the csv, probably costly, to re visit.

        //always re adding same thing here see https://github.com/Arachnid/solidity-stringutils
        for (uint i = 0; i < prescriptions[index].medications.length; i++) {
            medicationsCSV = prescriptions[index].medications[i].toSlice().concat(medicationsCSV.toSlice());
        }

        return (p.medicalPractitioner, p.dateCreated, medicationsCSV, p.dispensed, p.dispenser, p.dateDispensed);
    }

    event PrescriptionDispensed(string reference, address dispenser, address patient, uint dateDispensed, string medicationsCSV);

    function dispensePrescription(string reference, address patient) public returns(string) {

        uint index = prescriptionReferences[reference.toSlice().concat(toString(patient).toSlice())];

        if (index == 0) revert('Prescription does not exist'); //if prescription exists.
        if (patient != prescriptions[index].patient) require(patient == prescriptions[index].patient, 'Prescription does not belong to patient'); //check if patient prescribed is the patient being dispensed to.
        if (prescriptions[index].dispensed) require(!prescriptions[index].dispensed, 'Prescription is already dispensed'); //check if not already dispensed.

        uint medicalPractitionerIndex = medicalPractitionerMapping[msg.sender];
        if (medicalPractitionerIndex == 0) revert('Not a valid medical practitioner'); //means the sender address is not a medical practitioner. (index 0 is also taken by default unusuable value in cconstructor)
        if (medicalPractitioners[medicalPractitionerIndex].approved != true) require(medicalPractitioners[medicalPractitionerIndex].approved == true, 'Medical practitioner not yet approved'); //means the medical practitioner was not yet approved.
        if (medicalPractitioners[medicalPractitionerIndex].medicalPractitionerType != MedicalPractitionerType.BOTH &&
            medicalPractitioners[medicalPractitionerIndex].medicalPractitionerType != MedicalPractitionerType.DISPENSER) //medical practioner must by of MedicalPractitionerType BOTH or DISPENSER
            require(medicalPractitioners[medicalPractitionerIndex].medicalPractitionerType == MedicalPractitionerType.BOTH ||
                medicalPractitioners[medicalPractitionerIndex].medicalPractitionerType == MedicalPractitionerType.DISPENSER, 'Medical practioner must by of MedicalPractitionerType BOTH or DISPENSER');


        string memory medicationsCSV = "";
        prescriptions[index].dispensed = true;
        prescriptions[index].dispenser = msg.sender;
        prescriptions[index].dateDispensed = now;

        //concatenation to build the csv, probably costly, to re visit.
        for (uint i = 0; i < prescriptions[index].medications.length; i++) {
            //add comma here
            medicationsCSV = prescriptions[index].medications[i].toSlice().concat(medicationsCSV.toSlice());
        }

        emit PrescriptionDispensed(reference, prescriptions[index].dispenser, patient, prescriptions[index].dateDispensed, medicationsCSV);
    }

    function toString(address x) internal returns(string) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2 ** (8 * (19 - i)))));
        return string(b);
    }
}