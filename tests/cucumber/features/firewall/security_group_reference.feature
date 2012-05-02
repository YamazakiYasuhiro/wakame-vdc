Feature: Security groups referencing other security groups

  Scenario: Single nic
    Given the volume "wmi-secgtest" exists
      And the instance_spec "is-demospec" exists for api until 11.12
    And security group A exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      """
    And security group B exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      tcp:345,345,<Group A>
      """
    And security group C exists with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      """

    And an instance instB1 is started in group B that listens on tcp port 345
    And an instance instA1 is started in group A that listens on tcp port 345
    And an instance instA2 is started in group A that listens on tcp port 345
    And an instance instC1 is started in group C that listens on tcp port 345
    
    When instance instA1 sends a tcp packet to instance instB1 on port 345
    Then the packet should arrive successfully

    When instance instA2 sends a tcp packet to instance instB1 on port 345
    Then the packet should arrive successfully
    
    When instance instB1 sends a tcp packet to instance instA1 on port 345
    Then the packet should not arrive successfully
  
    When instance instB1 sends a tcp packet to instance instA2 on port 345
    Then the packet should not arrive successfully
    
    When instance instC1 sends a tcp packet to instance instB1 on port 345
    Then the packet should not arrive successfully
    
    When we successfully start an instance instA3 in group A that listens on tcp port 345
    And instance instA3 sends a tcp packet to instance instB1 on port 345
    Then the packet should arrive successfully
    
    When we update security group B with the following rules
      """
      tcp:22,22,ip4:0.0.0.0
      """
    
    When instance instA1 sends a tcp packet to instance instB1 on port 345
    Then the packet should not arrive successfully
    
    When instance instA2 sends a tcp packet to instance instB1 on port 345
    Then the packet should not arrive successfully
    
    When instance instA3 sends a tcp packet to instance instB1 on port 345
    Then the packet should not arrive successfully
    
    When we successfully terminate instance instA1
    And we successfully terminate instance instA2
    And we successfully terminate instance instA3
    And we successfully terminate instance instB1
    And we successfully terminate instance instC1
    And we successfully delete security group A
    And we successfully delete security group B
    And we successfully delete security group C