test("typeof", function() {
	assert_equal(typeof function() {}, "function");
});

test("undefined arguments", function() {
	function foo(a, b, c) {
		assert_equal(a, 1);
		assert_equal(b, undefined);
		assert_equal(c, undefined);
	}
	foo(1);
});

test("apply", function() {
	(function() {
		assert_equal(typeof this, "object");
		assert_equal(+this, 1);
	}).apply(1);
	
	(function(a, b, c) {
		assert_equal(typeof this, "object");
		assert_equal(Boolean(this), true);
		assert_equal(a, 1);
		assert_equal(b, "test");
		assert_equal(c, false);
	}).apply(true, [1, "test", false]);
});

test("bind", function() {
	var x = function(a) {
		a(this);
	};
	x.bind(1)(function(T) { assert_equal(Number(T), 1); });
	x.bind({ a: 1 })(function(T) { assert_equal(T.a, 1); });
	var obj = {
		foo: x.bind("not obj")
	};
	obj.foo(function(T) { assert_equal(String(T), "not obj"); });
});