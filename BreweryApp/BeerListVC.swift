//
//  BeerListVC.swift
//  BreweryApp
//
//  Copyright (c) 2023 oasis444. All right reserved.
//

import UIKit
import SwiftUI

class BeerListVC: UITableViewController {
    
    var beerList: [Beer] = []
    var dataTasks = [URLSessionTask]()
    var currentPage: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "🍺 맥주 목록! 🍺"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        tableView.register(BeerListCell.self, forCellReuseIdentifier: "BeerListCell")
        tableView.rowHeight = 150
        tableView.prefetchDataSource = self
        
        fetchBeer(of: currentPage)
    }
}

extension BeerListVC {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return beerList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BeerListCell") as? BeerListCell else { return UITableViewCell() }
        cell.configure(with: beerList[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedBeer = beerList[indexPath.row]
        let vc = BeerDetailVC()
        vc.beer = selectedBeer
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension BeerListVC: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        guard currentPage != 1 else { return }
        indexPaths.forEach {
            if ($0.row + 1)/25 + 1 == currentPage {
                self.fetchBeer(of: currentPage)
            }
        }
    }
}

private extension BeerListVC {
    func fetchBeer(of page: Int) {
        guard let url = URL(string: "https://api.punkapi.com/v2/beers?page=\(page)"),
              dataTasks.firstIndex(where: { $0.originalRequest?.url == url }) == nil
        else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let dataTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard error == nil,
                  let self = self,
                  let response = response as? HTTPURLResponse,
                  let data = data,
                  let beer = try? JSONDecoder().decode([Beer].self, from: data)
            else {
                print("Error: \(error?.localizedDescription ?? "")")
                return
            }
            
            switch response.statusCode {
            case (200...299):
                self.beerList += beer
                self.currentPage += 1
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            case (400...499):
                print("Client Error: \(response.statusCode)")
                print("Response: \(response)")
                
            case (500...599):
                print("Server Error: \(response.statusCode)")
                print("Response: \(response)")
                
            default:
                print("Error: \(response.statusCode)")
                print("Response: \(response)")
            }
        }
        dataTask.resume()
        dataTasks.append(dataTask)
    }
}
