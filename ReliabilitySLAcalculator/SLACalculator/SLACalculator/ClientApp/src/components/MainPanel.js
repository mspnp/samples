import React, { Component } from 'react';
import { Navigation } from './Navigation';
import { SearchBar } from './SearchBar';
import { Services } from './Services';

export class MainPanel extends Component {
    static displayName = MainPanel.name;

    constructor(props) {
        super(props);
        this.state = { serviceCategories: [], selectedServices: [], selectedCategory: "", filter: false, loading: true };
        this.selectCategory = this.selectCategory.bind(this);
        this.selectService = this.selectService.bind(this);
        this.searchTextEnter = this.searchTextEnter.bind(this);
        this.onClearSearch = this.onClearSearch.bind(this);
    }

    selectCategory(selectedCategory) {
        this.setState({
            selectedServices: selectedCategory.services,
            selectedCategory: selectedCategory.categoryName
        });
    }

    onClearSearch(evt) {
        evt.currentTarget.parentElement.children[0].value = "";

        let displayServices = this.state.allservices.filter(o => o.categoryName === this.state.selectedCategory);

        this.setState({
            selectedServices: displayServices,
            filter: false
        });
    }

    searchTextEnter(textValue) {
        let displayServices = [];
        let filter = false;

        if (textValue.length > 0) {
            displayServices = this.state.allservices.filter(o => o.name.toLowerCase().includes(textValue.toLowerCase()));
            filter = true;
        }
        else {
            displayServices = this.state.allservices.filter(o => o.categoryName === this.state.selectedCategory);
        }

        this.setState({
            selectedServices: displayServices,
            filter: filter
        });
    }


    selectService(selectedService) {
        this.setState({
            selectedService: selectedService
        });
    }

    componentDidMount() {
        this.populateServiceCategoryData();
    }

    renderMainPanel() {
        return (
            <div className="main-panel">
                <div className="top-title">
                    <h1 className="top-title-inner">SLA Estimator</h1>
                    <p className="top-title-inner-sub">Estimate the oeverall service level agreement of your services</p>
                </div>
                <div className="search-container">
                    <SearchBar onTextSearchEnter={this.searchTextEnter} onClearSearch={this.onClearSearch} />
                </div>
                <div className="layout-parent-div">
                    <div className={!this.state.filter ? "layout-div-left" : "div-hide"}>
                        <Navigation visible={!this.state.filter} dataSource={this.state.serviceCategories} selectedCategory={this.state.selectedCategory} onSelectCategory={this.selectCategory} />
                    </div>
                    <div className={this.state.filter ? "layout-div-center" : "layout-div-right"}>
                        <Services dataSource={this.state.selectedServices} onSelectService={this.selectService} />
                    </div>
                </div>
            </div>
        );
    }

    render() {
        let contents = this.renderMainPanel();

        return (
            <div>
                {contents}
            </div>
        );
    }

    async populateServiceCategoryData() {
        const response = await fetch('servicecategory');
        const data = await response.json();

        const allservices = data.map(x => x.services).reduce(
            (x, y) => x.concat(y));

        this.setState({ serviceCategories: data, allservices, selectedServices: data[0].services, selectedCategory: data[0].categoryName, loading: false });
    }
}
