# Lab 2 

### Simularea unui blocking queue

Folosim un lock codat manual in locul keyword-ului synchronise (e acelasi lucru dar trebuie mentionat de mana cand e blocat accesul la metoda/ clasa respectiva). Obiectul este de tipul ```ReentractLock``` si are metode specifice (de ex ```lock()``` si ```unlock()```)

```java
// vrem sa simulam un Blockchain - inclusiv PoW (tot simulat cu un random)
// PoW - cautam un hash cu o problema grea / o constrangere dificila asupra hash-ului
// Transaction, Block, Blockchain, Node 

import java.util.*;
import java.util.concurrent.BlockingQueue; 
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.locks.ReentrantLock;

class Transaction {
  private String id; 

  public Transaction(String id) {
    this.id = id; 
  }

  public String getId() {
    return id; 
  }
}

class Block {
  private int index; 
  private List<Transaction> transactions; 
  private String previousHash; 
  private String hash; 

  public Block(int index, List<Transaction> transactions, String previousHash) {
    this.index = index; 
    this.transactions = transactions;
    this.previousHash = previousHash;
    this.hash = computeHash();
  }

  private String computeHash() {
    return Integer.toHexString(Objects.hash(index, transactions, previousHash));
  }

  public String getHash() {
    return hash; 
  }

  public String getPreviousHash() {
    return previousHash;
  }

  public int getIndex() {
    return index;
  }
}

class Blockchain {
  private List<Block> chain = new ArrayList<>();
  private ReentrantLock lock = new ReentrantLock(); 

  public Blockchain() {
    chain.add(new Block(0, new ArrayList<>(), "0"));
  }

  public void addBlock(Block block) {
    lock.lock();
    try {
      if (chain.get(chain.size() - 1).getHash().equals(block.getPreviousHash())) {
        chain.add(block);
        System.out.println("Block added: " + block.getIndex() + " with hash " + block.getHash());
      }
    }
    catch (Exception ex) {
      ex.printStackTrace();
    }
    finally {
      lock.unlock();
    }
  }

  public Block getLastBlock() {
    return chain.get(chain.size() - 1);
  }
}

class Node implements Runnable {
  private BlockingQueue<Transaction> transactionPool;
  private Blockchain blockchain; 
  private String nodeId; 

  public Node(String nodeId, Blockchain blockchain, BlockingQueue<Transaction> transactionPool) {
    this.nodeId = nodeId;
    this.blockchain = blockchain;
    this.transactionPool = transactionPool;
  }

  @Override 
  public void run() {
    while (true) {
      try {
        List<Transaction> transactions = new ArrayList<>();
        transactionPool.drainTo(transactions, 5);

        if (!transactions.isEmpty()) {
          Block previousBlock = blockchain.getLastBlock();
          Block newBlock = new Block(previousBlock.getIndex() + 1, transactions, previousBlock.getHash());

          // PoW - sta un moment de timp pentru a rezolva problema complicata dpdv computational 
          Thread.sleep((long) (Math.random() * 600));

          blockchain.addBlock(newBlock);
        }
        else {
          System.out.println(nodeId + " found no transactions, waiting...");
          Thread.sleep(6000);
        }

      }
      catch (InterruptedException ex) {
        ex.printStackTrace();
      }
    }
  }
}

public class Main {
    public static void main(String[] args) {
      BlockingQueue<Transaction> transactionPool = new LinkedBlockingQueue<>();
      Blockchain blockchain = new Blockchain();

      Thread node1 = new Thread(new Node("Node1", blockchain, transactionPool));
      Thread node2 = new Thread(new Node("Node2", blockchain, transactionPool));
      Thread node3 = new Thread(new Node("Node3", blockchain, transactionPool));

      node1.start();
      node2.start();
      node3.start();

      for (int i = 0; i < 100; i++) {
        System.out.println("Added transaction " + i);
        transactionPool.add(new Transaction("Transaction " + i));

        try {
          Thread.sleep((long) (Math.random() * 500));
        }
        catch (InterruptedException ex) {
          ex.printStackTrace();
        }
      }
    }
}
```


### Ex de laborator 
Probleme pentru restul laboratorului:
1. Implementati un counter in Java, folosind sincronizare atat cu synchronized, cat si cu reentrantLock-uri (ca in problema de mai sus)

```java
import java.util.*;
import java.util.concurrent.locks.ReentrantLock;
/*
Probleme pentru restul laboratorului:
1. Implementati un counter in Java, folosind sincronizare atat cu synchronized, 
cat si cu reentrantLock-uri (ca in problema de mai sus)
*/

class Counter {
  private ReentrantLock lock = new ReentrantLock();
  private int count;

  public Counter(){
    this.count = 0;
  }

  public int getCount(){
    return count;
  }

  public void IncreaseCounter(String nodeId) {
    lock.lock();
    try {
      count += 1;
      System.out.println("Current counter: " + this.count + ". Increased by: " + nodeId);
    }
    catch(Exception ex){
      ex.printStackTrace();
    }

    lock.unlock();
  }
}

class Node implements Runnable { 
  private String nodeId;
  private Counter counterStructure;

  public String getId(){
    return this.nodeId;
  }

  public Node(String nodeId, Counter count){
    this.nodeId = nodeId;
    this.counterStructure = count;
  }

  @Override 
  public void run(){
    while(counterStructure.getCount() < 10000){
      this.counterStructure.IncreaseCounter(nodeId);
    }
  } 
}


public class Main {
    public static void main(String[] args) {      
      Counter counter = new Counter();
      Thread nod1 = new Thread(new Node("nod 1", counter));
      Thread nod2 = new Thread(new Node("nod 2", counter));
      Thread nod3 = new Thread(new Node("nod 3", counter));

      nod1.start();
      nod2.start();
      nod3.start();
    }
}
```

### Ex pe care il da absolut mereu (putin schimbat though) la examen!!!!!!!!
2. Scrieti un model de producer-consumer prin care producatorii parcurg o ierarhie de foldere, citesc continutul fisierelor .txt si adauga continutul acestora intr-un buffer. Consumatorii citesc din buffer si afiseaza la STDOUT continutul cu o modificare asupra lui, la alegere (de exemplu, toUpper pe text)
