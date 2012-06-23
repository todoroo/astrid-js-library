// Astrid JS API example

var assert = function(result) {
  if(!result)
    throw "Assertion error: " + result;
}

var print = function(message) {
  if(window.console)
    window.console.log(message); // authorized
}

// --- initialize

var SERVER = "http://astrid.com";
var APIKEY = "apikey";
var SECRET = "secret";

var astrid = new Astrid(SERVER, APIKEY, SECRET);

// --- sign in

assert(false == astrid.isSignedIn());

var token = localStorage.getItem("astrid-token");

if(!token) {

  print("Signing In");

  astrid.signInAs("example@example.com", "example!", function(user) {

    assert(true == astrid.isSignedIn());

    localStorage.setItem("astrid-token", user.token);

    getListsAndTasks();

  }, function(message) {
    throw message;
  });

} else {

  astrid.setToken(token);
  getListsAndTasks();

}

// --- get lists

function getListsAndTasks() {

  print("Getting Lists");

  astrid.getLists(function(lists) {

    assert(lists.length > 0);

    print(lists[0].name);

    // --- create tasks

    print("Creating a Task");

    var task = {
      title: "A great task",
      notes: "With great tasks come great responsibility",
      source: "http://www.google.com",
      due: new Date(2012, 6, 30).getTime() / 1000,
      has_due_time: false,
      tag_ids: [ lists[0].id ]
    };
  
    astrid.createTask(task, function(result) {

      assert(task.title == result.title);

      assert(result.created_at > 0);

    });

    var badTask = {};

    astrid.createTask(badTask, function() { 

      throw "Created task when we weren't expecting it";

    }, function(message) {

      assert(message.length > 0);

    });

  });

}

