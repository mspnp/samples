import React, { Component } from 'react';
import { Navigation } from './Navigation';
import { Services } from './Services';

export class Layout extends Component {
    static displayName = Layout.name;

    constructor(props) {
        super(props);
        this.state = { serviceCategories: [], selectedServices: [], selectedCategory: "", loading: true };
        this.selectCategory = this.selectCategory.bind(this);
        this.selectService = this.selectService.bind(this);
    }

    selectCategory(selectedCategory) {
        this.setState({
            selectedServices: selectedCategory.services,
            selectedCategory: selectedCategory.categoryName
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

    render() {
                //let contents = this.state.loading
        //    ? <p><em>Loading...</em></p>
        //    : Navigation.renderCategoriesTable(this.props.serviceCategory, this.props.selectCategory);
        return (
            <div>
                <div>
                    <h1 className="titles">SLA Estimator</h1>
                    <p className="titles">Estimate the oeverall service level agreement of your services</p>
                </div>
                <div className="layoutParentDiv">
                    <div className="layoutDivLeft">
                        <Navigation dataSource={this.state.serviceCategories} selectedCategory={this.state.selectedCategory} onSelectCategory={this.selectCategory} />
                    </div>
                    <div className="layoutDivRight">
                        <Services dataSource={this.state.selectedServices} onSelectService={this.selectService} />
                    </div>
                </div>
            </div>
        );
    }

    async populateServiceCategoryData() {
        const response = await fetch('servicecategory');
        const data = await response.json();
        this.setState({ serviceCategories: data, selectedServices: data[0].services, selectedCategory: data[0].categoryName, loading: false });
    }
}
