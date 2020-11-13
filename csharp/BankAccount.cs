using System;

// This class models a minimal bank account (with selection).
public class BankAccount 
{
  // Fields
  // Each BankAccount object will have its balance, ID, and PIN
  private double balance;
  private string id;
  private string pin;

  // Constructor
  // Initializes the fields 
  public BankAccount(string init_id, double init_balance)
  {
    id = init_id;
    balance = init_balance;
    pin = null;    
  }

  // Properties
  // Allow access to an account's balance (gettable, not settable)
  public double Balance
  {
    get { return Math.Round(balance, 2); }
  }

  // Provide access to an account's ID (gettable, not settable)
  public string ID
  {
    get { return id; }
  }

  // Provide access to an account's PIN (gettable and settable)
  public string PIN
  {
    get { return pin; }   // Provides the value of the field
    set { pin = value; }  // changes the field
  }

  // Methods
  // Credit this account by amount. 
  // If amount is negative, return false.
  public bool Deposit(double amount)
  {
    bool result = true;

    if (amount <= 0.00)
      result = false;
    else
      balance = balance + amount; 

    return result;
  }

  // Debit this account by amount.
  // If amount is negative, has no effect on account's balance.
  // If amount > account balance, debit by amount and return true.
  public bool Withdraw(double amount)
  {
    bool result = true;

    if (amount > balance || amount <= 0.00)
      result = false;
    else
      balance = balance - amount; 

    return result;
  }

  // Returns a string representation of this account.
  public override string ToString()
  {
    return string.Format("{0} {1:C}", id, balance);
  }
} // End class BankAccount