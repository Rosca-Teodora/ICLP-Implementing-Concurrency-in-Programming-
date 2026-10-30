# Lab 4

## Implementare simpla async/ await
Lansez un thread (**callable**) si astept sa returneze ceva (**future**). 
```

|------------|       callable
|            |---------------->|--------|
|   thread   |                 | thread |
|   princip  |                 | separat|
|            |<----------------|--------|
|------------|   future

```

```java
// Future si Callable 

import java.util.concurrent.Callable;
import java.util.concurrent.FutureTask;

public class Main {
    public static void main(String[] args) {
      // Callable<String> task = new MyTask();
      Callable<String> task = () -> {
        Thread.sleep(2000);
        return "Task completed";
      };

      FutureTask<String> futureTask = new FutureTask<>(task);

      Thread thread = new Thread(futureTask);
      thread.start();

      try {
        System.out.println("Main...");
        String result = futureTask.get();
        System.out.println("Result is: " + result);
      }
      catch (Exception ex) {
        ex.printStackTrace();
      }
    }
}

class MyTask implements Callable<String> {
  @Override 
  public String call() {
    try {
      Thread.sleep(2000);
      return "Task completed";
    }
    catch (InterruptedException ex) {
      ex.printStackTrace();
      return "ERROR";
    }
  }
}
```

## Aplicatie practica pentru callable/ future
Face un site crawler. Un watcher pus pe o lista de URL-uri, mai multe thread-uri care ruleaza in paralel, un thread se ocupa de un URL. ("problema buna de examen" - Macovei)

```java
// scriem un Crawler cu Callable si FutureTask 
// vrem sa accesam continutul unor site-uri si sa afisam acest continut la stdout 
 
import java.io.BufferedReader;
import java.io.InputStreamReader;
 
import java.util.concurrent.Callable;
import java.util.concurrent.FutureTask;
 
import java.net.URL;
import java.net.HttpURLConnection;
 
import java.util.List;
import java.util.ArrayList;
 
 
public class Main {
    public static void main(String[] args) {
      List<String> urls = List.of(
        "https://fmi.unibuc.ro",
        "https://jsonplaceholder.typicode.com/posts/1",
        "https://jsonplaceholder.typicode.com/posts/2",
        "https://jsonplaceholder.typicode.com/posts/3",
        "https://google.com"
      );
 
      List<FutureTask<String>> futureTasks = new ArrayList<>();
 
      for (String url : urls) {
        Callable<String> task = new CrawlerTask(url);
        FutureTask<String> futureTask = new FutureTask<>(task);
        futureTasks.add(futureTask);
        Thread thread = new Thread(futureTask);
        thread.start();
      }
        
      for (FutureTask<String> futureTask : futureTasks) {
        try {
          String content = futureTask.get();
          System.out.println("Page content:\n" + content);
        }
        catch (Exception ex) {
          ex.printStackTrace();
        }
      }
  }
}
 
class CrawlerTask implements Callable<String> {
  private String url; 
 
  public CrawlerTask(String url) {
    this.url = url; 
  }
 
  @Override 
  public String call() {
    StringBuilder content = new StringBuilder();
 
    try {
      System.out.println("Accessing: " + url);
      
      // pregatim requestul http 
      HttpURLConnection connection = (HttpURLConnection) new URL(url).openConnection();
      connection.setRequestMethod("GET");
      connection.setConnectTimeout(5000);
      connection.setReadTimeout(5000);
 
      int status = connection.getResponseCode();
 
      if (status == 200) {
        BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
        String line;
        while ((line = reader.readLine()) != null) {
          content.append(line).append("\n");
        }
        reader.close();
      }
      else {
        content.append("Cannot acces ").append(url).append(status);
      }
      connection.disconnect();
    }
    catch (Exception ex) {
      ex.printStackTrace();
      return "Error " + url;
    }
 
    return content.toString();
  }
}
```

Si daca as combina cele doua idei (callable/ future) intr-una singura? -> **CompletableFuture** 

```java
import java.util.concurrent.CompletableFuture;

public class Main {
    public static void main(String[] args) {
      int n = 20; 
      System.out.println("Fibonacci for n = " + n);

      CompletableFuture<Long> future = CompletableFuture.supplyAsync(() -> fibonacci(n));
      future.thenAccept(result -> {
        System.out.println("Fibonacci(" + n + ") = " + result);
      });

      System.out.println("MAIN");

      future.join();
    }

    public static long fibonacci(int n) {
      if (n <= 1) {
        return n;
      }
      return fibonacci(n - 1) + fibonacci(n - 2);
    }
}
```



## Incrementarea unui contor cu valori atomice 
**Variabila atomica** = garanteaza sincronizarea -> ele sunt gestionate la nivel hardware, sunt foarte low-level si dispare interferenta. 

```java
// incrementarea unui contor cu variabile atomice 

import java.util.concurrent.atomic.AtomicInteger;

public class Main {
    private static AtomicInteger counter = new AtomicInteger();
  
    public static void main(String[] args) throws InterruptedException {
      Thread t1 = new Thread(new Runnable() {
        public void run() {
          for (int i = 0; i < 1000; i++) {
            counter.incrementAndGet();
          }
        }
      });

      Thread t2 = new Thread(new Runnable() {
        public void run() {
          for (int i = 0; i < 1000; i++) {
            counter.incrementAndGet();
          }
        }
      });

      t1.start();
      t2.start();

      t1.join();
      t2.join();

      System.out.println("Counter is " + counter);
    }
}
```

### Sincronizare prin: 
- Semaphore (permits) 

    | LOCK | SEMAPHORE |
    |------|-----------|
    |  poate fi facut doar de thread-ul care a creat lock-ul     | orice thread poate face release asupra semaforului           |

- ContDownLatch -> avem un thread principal care lanseaza alte *n* thread-uri si poate face un <u>await</u> doar dupa ce au terminat cele *n* thread-uri (executie blocata pana primim semnal de la toate thread-urile)

- CyclicBarrier -> toate thread-urile sunt blocate pana ajung intr-un anumit punct. OBS: param. nr de thread-uri

| COUNT DOWN LATCH | CYCLIC BARRIER|
|-----------------|----------------|
|**nu** este reutilizabil|**este** reutilizabil, dar punem barrier.await()|

## Implementare **CountDownLatch**

**LA EXAMEN:** "un anumit lucru nu se poate executa pana cand nu avem minim 3 actiuni complete" 

```java 
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

public class Main {
    public static void main(String[] args) throws InterruptedException {
      CountDownLatch controller = new CountDownLatch(3);

      ExecutorService pool = Executors.newCachedThreadPool();
      
      AtomicInteger counter = new AtomicInteger(0);

      for (int i = 0; i < 3; i++) {
        pool.execute(new MyTask(controller, counter));
      }

      controller.await();       // apelul este blocant pana cand toate cele trei thread-uri create dau semnalul countDown 

      System.out.println("Counter ***** await: " + counter);

      pool.shutdown();
      try {
        if (!pool.awaitTermination(3, TimeUnit.SECONDS)) {
          pool.shutdownNow();
        }
      }
      catch (InterruptedException ex) {
        ex.printStackTrace();
        pool.shutdownNow();
      }
      
      System.out.println("Counter la final: " + counter);
    }
}

class MyTask implements Runnable {
  private AtomicInteger counter;
  private CountDownLatch controller; 

  public MyTask(CountDownLatch controller, AtomicInteger counter) {
    this.controller = controller;
    this.counter = counter;
  }

  @Override 
  public void run() {
    for (int i = 0; i < 100; i++) {
      counter.incrementAndGet();
    }
    controller.countDown();
    for(int i = 0; i < 1000; i++) {
      counter.incrementAndGet();
    }
  }
}
```

## Implementare Cyclic Barrier 

```java
import java.util.concurrent.CyclicBarrier;

public class Main {
    public static void main(String[] args) {
      CyclicBarrier barrier = new CyclicBarrier(3);

      for (int i = 0; i < 3; i++) {
        int id = i; 

        new Thread(() -> {
          try {
            System.out.println("Thread " + id + " - stage 1");
            Thread.sleep(1000 * (id + 1));

            barrier.await();

            System.out.println("Thread " + id + " - stage 2");
            barrier.await();

            System.out.println("Thread " + id + " finalized");
          }
          catch (Exception ex) {
            ex.printStackTrace();
          }
        }).start();
      }
    }
}
```