
# Create a new Google Project 
provider "google" {
  credentials = "${var.gcp_credentials}"
  project     = "${var.project}"
  region      = "us-central1"
}

resource "google_project" "new_project" {
  name            = "${var.project}"
  project_id      = "${var.project}"
  folder_id       = "${var.folder_id}"
  billing_account = "${var.billing_account}"
  auto_create_network = false
}

resource "google_service_account" "project_admin" {
  account_id   = "project-admin"
  display_name = "Project Admin"
  project      = "${google_project.new_project.project_id}"
}

resource "google_project_iam_member" "project" {
  project = "${google_project.new_project.project_id}"
  role    = "roles/editor"
  member  = "user:${var.iam_user_email}"
}

 
resource "google_project_service" "cloud_compute" {
  project = "${google_project.new_project.project_id}"
  service = "compute.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "kubernetes" {
  project = "${google_project.new_project.project_id}"
  service = "container.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "billing" {
  project = "${google_project.new_project.project_id}"
  service = "cloudbilling.googleapis.com"
  disable_dependent_services = true
}


module "network" {
  source                     = "./modules/network"
  name                       = "${var.project}"
  project                    = "${google_project.new_project.project_id}"
  region                     = "${var.region}"
  zones                      = "${var.zones}"
  webservers_subnet_name     = "webservers"
  webservers_subnet_ip_range = "${var.webservers_subnet_ip_range}"
  management_subnet_name     = "management"
  management_subnet_ip_range = "${var.management_subnet_ip_range}"
  bastion_image              = "${var.bastion_image}"
  bastion_instance_type      = "${var.bastion_instance_type}"
  user                       = "${var.ssh_user}"
  ssh_key                    = "${var.ssh_key}"
}

module "mysql-db" {
  source           = "./modules/db"
  db_name          = "${var.project}"
  project          = "${google_project.new_project.project_id}"
  region           = "${var.region}"
  db_name          = "${var.project}"
  user_name        = "hello"
  user_password    = "hello"
}

module "instance-template" {
  source          = "./modules/instance-template"
  name            = "${var.project}"
  env             = "${var.env}"
  project         = "${google_project.new_project.project_id}"
  region          = "${var.region}"
  network_name    = "${module.network.name}"
  subnetwork_name = "${module.network.webservers_subnet}"
  image           = "${var.app_image}"
  instance_type   = "${var.app_instance_type}"
  user            = "${var.ssh_user}"
  ssh_key         = "${var.ssh_key}"
  db_name         = "${var.project}}"
  db_user         = "hello"
  db_password     = "hello"
  db_ip           = "${module.mysql-db.instance_address}"
  }

/*
module "lb" {
  source            = "./modules/lb"
  name              = "${var.project}"
  project           = "${google_project.new_project.project_id}"
  region            = "${var.region}"
  count             = "${var.appserver_count}"
  instance_template = "${module.instance-template.instance_template}"
  zones             = "${var.zones}"
}

*/

/*
module "cluster" {
  source = "./modules/cluster"

  region = "${var.region}"
  zone = "${var.zones[0]}"

  platform_name = "${var.platform_name}"

  network_name = "${module.network.name}"
  subnetwork_name = "${module.network.webservers_subnet}"

  cluster_node_machine_type = "${var.cluster_node_machine_type}"
  cluster_node_initial_count = "${var.cluster_node_initial_count}"

  cluster_master_auth_username = "${var.cluster_master_auth_username}"
  cluster_master_auth_password = "${var.cluster_master_auth_password}"
}

*/


