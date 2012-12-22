module ParseSpecHelper
  def assert_link(link, kind, location, has_problem, problem=nil)
		link.kind.should eql(kind)
		link.location.should eql(location)
		link.has_problem?.should eql(has_problem)
		link.problem.should eql(problem) if problem
	end
end