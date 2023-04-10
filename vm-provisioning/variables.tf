variable "bashscriptfile" {
  default = "testfile.sh"
}

// make this object
/*
  vm01 :{
    vm: vm-name
    nic: nic-name
    disk_type: disk-type
  }
  vm001:{
    vm: vm-name
    nic: nic-name
    disk_type: disk-type
  }
*/
variable "vmmachines" {
  default = ["my-vm01", "my-server001", "my-cloud0001"]
}

variable "vms" {
  default = {
    "my-vm01" : {
      nic : "testnicvm01"
      disk_type : "StandardSSD_LRS"
    }
    "my-vm001" : {
      nic : "testnicvm001"
      disk_type : "Standard_LRS"
    }
    "my-vm0001" : {
      nic : "testnicvm0001"
      disk_type : "Standard_LRS"
    }
  }
}
