import '../models/job_model.dart';

class JobService {
  static final List<Job> _jobs = [
    Job(
      id: "1",
      title: "Leaky Pipe under Kitchen Sink",
      category: "Plumbing",
      description:
          "The main pipe under the kitchen sink has a steady drip and needs quick repair.",
      address: "No.63, 2/8 Cross Street, Athurugiriya",
      distance: 1.0,
      estimatedPrice: 3500,
      rating: 4.5,
      urgency: "Emergency",
    ),
    Job(
      id: "2",
      title: "Washing Machine Drain Leak",
      category: "Plumbing",
      description:
          "Drain hose is leaking during spin cycle and water is pooling on the floor.",
      address: "Hokandara Road, Hokandara",
      distance: 2.6,
      estimatedPrice: 3200,
      rating: 4.3,
      urgency: "Normal",
    ),
    Job(
      id: "5",
      title: "Circuit Breaker Trips Frequently",
      category: "Electrical",
      description:
          "Main breaker trips when the microwave and kettle are on together.",
      address: "Pannipitiya Main Road, Pannipitiya",
      distance: 4.1,
      estimatedPrice: 4100,
      rating: 4.6,
      urgency: "Emergency",
    ),
    Job(
      id: "6",
      title: "Bathroom Tap Replacement",
      category: "Plumbing",
      description: "Need to replace the old bathroom mixer tap with a new one.",
      address: "Lake Road, Nugegoda",
      distance: 3.2,
      estimatedPrice: 2800,
      rating: 4.2,
      urgency: "Normal",
      status: "accepted",
    ),
    Job(
      id: "3",
      title: "AC Outdoor Unit Servicing",
      category: "HVAC",
      description:
          "Outdoor AC unit has reduced cooling and requires servicing.",
      address: "Malabe Town, Malabe",
      distance: 5.0,
      estimatedPrice: 4500,
      rating: 4.7,
      urgency: "Normal",
      status: "completed",
      completedAt: DateTime(2026, 3, 6),
    ),
    Job(
      id: "4",
      title: "Ceiling Fan Wiring Repair",
      category: "Electrical",
      description: "Main bedroom ceiling fan has intermittent power issue.",
      address: "Kottawa Junction, Kottawa",
      distance: 4.4,
      estimatedPrice: 2200,
      rating: 4.4,
      urgency: "Normal",
      status: "completed",
      completedAt: DateTime(2026, 3, 4),
    ),
  ];

  List<Job> getNewJobs() {
    return _jobs.where((job) => job.status == "pending").toList();
  }

  List<Job> getScheduledJobs() {
    return _jobs.where((job) => job.status == "accepted").toList();
  }

  List<Job> getCompletedJobs() {
    return _jobs.where((job) => job.status == "completed").toList();
  }

  void acceptJob(String jobId) {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    job.status = "accepted";
  }

  void declineJob(String jobId) {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    job.status = "declined";
  }
}
